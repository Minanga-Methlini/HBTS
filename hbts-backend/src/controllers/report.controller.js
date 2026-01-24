import { pool } from "../db.js";
import PDFDocument from "pdfkit";
import ExcelJS from "exceljs";

const formatDate = (value) => {
  if (!value) return "";
  const d = value instanceof Date ? value : new Date(value);
  if (Number.isNaN(d.getTime())) return "";
  const y = d.getFullYear().toString().padStart(4, "0");
  const m = (d.getMonth() + 1).toString().padStart(2, "0");
  const day = d.getDate().toString().padStart(2, "0");
  return `${y}-${m}-${day}`;
};

const defaultRange = () => {
  const to = new Date();
  const from = new Date(to);
  from.setDate(to.getDate() - 30);
  return { from: formatDate(from), to: formatDate(to) };
};

const tableCache = new Map();

const getColumns = async (tableName) => {
  if (tableCache.has(tableName)) return tableCache.get(tableName);
  const { rows } = await pool.query(
    `
      SELECT column_name
      FROM information_schema.columns
      WHERE table_name = $1
    `,
    [tableName]
  );
  const columns = rows.map((r) => r.column_name);
  tableCache.set(tableName, columns);
  return columns;
};

const pickColumn = (columns, candidates) =>
  candidates.find((c) => columns.includes(c));

const buildReportData = async ({ from, to }) => {
  const range = defaultRange();
  const fromDate = formatDate(from) || range.from;
  const toDate = formatDate(to) || range.to;

  const [{ rows: passengerTotals }] = await Promise.all([
    pool.query(
      `
      SELECT
        COUNT(*)::int AS total_passengers,
        COUNT(*) FILTER (
          WHERE u.created_at::date BETWEEN $1::date AND $2::date
        )::int AS new_passengers
      FROM users u
      JOIN roles r ON u.role_id = r.role_id
      WHERE r.role_name = 'passenger'
        AND u.deleted_at IS NULL
      `,
      [fromDate, toDate]
    ),
  ]);

  const tripsStatus = await pool.query(
    `
    SELECT t.status::text AS status, COUNT(*)::int AS total
    FROM trips t
    WHERE t.trip_date::date BETWEEN $1::date AND $2::date
    GROUP BY t.status
    `,
    [fromDate, toDate]
  );

  const tripsTotal = await pool.query(
    `
    SELECT COUNT(*)::int AS total
    FROM trips t
    WHERE t.trip_date::date BETWEEN $1::date AND $2::date
    `,
    [fromDate, toDate]
  );

  const driverColumns = await getColumns("drivers");
  const routeColumns = await getColumns("routes");
  const busColumns = await getColumns("buses");

  const driverNameCol = pickColumn(driverColumns, [
    "name",
    "full_name",
    "driver_name",
    "fullName",
    "driverName",
  ]);
  const routeNameCol = pickColumn(routeColumns, [
    "route_name",
    "name",
    "routeName",
  ]);
  const routeCodeCol = pickColumn(routeColumns, [
    "route_no",
    "route_code",
    "route_number",
    "code",
  ]);
  const busPlateCol = pickColumn(busColumns, [
    "license_plate_no",
    "license_plate",
  ]);

  const selectExtras = [
    driverNameCol
      ? `d."${driverNameCol}" AS driver_name`
      : "NULL AS driver_name",
    routeNameCol
      ? `r."${routeNameCol}" AS route_name`
      : "NULL AS route_name",
    routeCodeCol
      ? `r."${routeCodeCol}" AS route_code`
      : "NULL AS route_code",
    busPlateCol
      ? `b."${busPlateCol}" AS license_plate_no`
      : "NULL AS license_plate_no",
  ];

  const tripsList = await pool.query(
    `
    SELECT t.*, ${selectExtras.join(", ")}
    FROM trips t
    LEFT JOIN routes r ON r.route_id = t.route_id
    LEFT JOIN buses b ON b.bus_id = t.bus_id
    LEFT JOIN drivers d ON d.driver_id = t.driver_id
    WHERE t.trip_date::date BETWEEN $1::date AND $2::date
    ORDER BY t.trip_date DESC, t.trip_id DESC
    `,
    [fromDate, toDate]
  );

  const statusTotals = tripsStatus.rows.reduce((acc, row) => {
    const key = (row.status ?? "").toLowerCase();
    acc[key] = row.total ?? 0;
    return acc;
  }, {});

  return {
    range: { from: fromDate, to: toDate },
    summary: {
      passengers_total: passengerTotals[0]?.total_passengers ?? 0,
      passengers_new: passengerTotals[0]?.new_passengers ?? 0,
      trips_total: tripsTotal.rows[0]?.total ?? 0,
      trips_scheduled: statusTotals.scheduled ?? 0,
      trips_in_progress: statusTotals.in_progress ?? 0,
      trips_completed: statusTotals.completed ?? 0,
      trips_cancelled: statusTotals.cancelled ?? 0,
    },
    trips: tripsList.rows ?? [],
  };
};

export const driverStatusReport = async (req, res) => {
  try {
    const result = await pool.query(`
      SELECT status, COUNT(*) AS total
      FROM drivers
      GROUP BY status
    `);

    res.json(result.rows);
  } catch (error) {
    console.error("Driver status report error:", error);
    res.status(500).json({ message: "Failed to generate report" });
  }
};

export const reportSummary = async (req, res) => {
  try {
    const data = await buildReportData({
      from: req.query.from,
      to: req.query.to,
    });
    res.json(data);
  } catch (error) {
    console.error("Summary report error:", error);
    res.status(500).json({ message: "Failed to generate report" });
  }
};

export const reportSummaryPdf = async (req, res) => {
  try {
    const data = await buildReportData({
      from: req.query.from,
      to: req.query.to,
    });

    const doc = new PDFDocument({ margin: 40, size: "A4" });
    res.setHeader("Content-Type", "application/pdf");
    res.setHeader(
      "Content-Disposition",
      `attachment; filename="report-summary-${data.range.from}-to-${data.range.to}.pdf"`
    );

    doc.pipe(res);
    doc.fontSize(18).text("HBTS Report Summary", { align: "left" });
    doc.moveDown(0.5);
    doc.fontSize(12).text(`Date Range: ${data.range.from} to ${data.range.to}`);

    doc.moveDown();
    doc.fontSize(14).text("Summary");
    doc.moveDown(0.3);
    doc.fontSize(11);
    doc.text(`Total Passengers: ${data.summary.passengers_total}`);
    doc.text(`New Passengers: ${data.summary.passengers_new}`);
    doc.text(`Total Trips: ${data.summary.trips_total}`);
    doc.text(`Scheduled Trips: ${data.summary.trips_scheduled}`);
    doc.text(`In Progress Trips: ${data.summary.trips_in_progress}`);
    doc.text(`Completed Trips: ${data.summary.trips_completed}`);
    doc.text(`Cancelled Trips: ${data.summary.trips_cancelled}`);

    doc.moveDown();
    doc.fontSize(14).text("Trips");
    doc.moveDown(0.3);
    doc.fontSize(9);
    const rows = data.trips.slice(0, 500);
    rows.forEach((trip) => {
      const line = [
        `#${trip.trip_id ?? "-"}`,
        trip.route_name ?? trip.route_code ?? "-",
        trip.license_plate_no ?? "-",
        trip.driver_name ?? "-",
        formatDate(trip.trip_date),
        trip.status ?? "-",
      ].join(" | ");
      doc.text(line);
    });

    doc.end();
  } catch (error) {
    console.error("Summary PDF error:", error);
    res.status(500).json({ message: "Failed to generate PDF report" });
  }
};

export const reportSummaryExcel = async (req, res) => {
  try {
    const data = await buildReportData({
      from: req.query.from,
      to: req.query.to,
    });

    const workbook = new ExcelJS.Workbook();
    const summarySheet = workbook.addWorksheet("Summary");
    summarySheet.addRow(["HBTS Report Summary"]);
    summarySheet.addRow([`Date Range: ${data.range.from} to ${data.range.to}`]);
    summarySheet.addRow([]);
    summarySheet.addRow(["Total Passengers", data.summary.passengers_total]);
    summarySheet.addRow(["New Passengers", data.summary.passengers_new]);
    summarySheet.addRow(["Total Trips", data.summary.trips_total]);
    summarySheet.addRow(["Scheduled Trips", data.summary.trips_scheduled]);
    summarySheet.addRow(["In Progress Trips", data.summary.trips_in_progress]);
    summarySheet.addRow(["Completed Trips", data.summary.trips_completed]);
    summarySheet.addRow(["Cancelled Trips", data.summary.trips_cancelled]);

    const tripsSheet = workbook.addWorksheet("Trips");
    tripsSheet.addRow([
      "Trip ID",
      "Route",
      "Route Code",
      "Bus",
      "Driver",
      "Trip Date",
      "Departure",
      "Arrival",
      "Status",
    ]);
    data.trips.forEach((trip) => {
      tripsSheet.addRow([
        trip.trip_id ?? "",
        trip.route_name ?? "",
        trip.route_code ?? "",
        trip.license_plate_no ?? "",
        trip.driver_name ?? "",
        formatDate(trip.trip_date),
        trip.departure_time ?? "",
        trip.arrival_time ?? "",
        trip.status ?? "",
      ]);
    });

    res.setHeader(
      "Content-Type",
      "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"
    );
    res.setHeader(
      "Content-Disposition",
      `attachment; filename="report-summary-${data.range.from}-to-${data.range.to}.xlsx"`
    );

    await workbook.xlsx.write(res);
    res.end();
  } catch (error) {
    console.error("Summary Excel error:", error);
    res.status(500).json({ message: "Failed to generate Excel report" });
  }
};
