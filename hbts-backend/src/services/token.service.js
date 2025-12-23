import jwt from "jsonwebtoken";

export function signTempToken(userId) {
  return jwt.sign(
    { sub: userId, type: "TEMP_2FA" },
    process.env.JWT_TEMP_SECRET,
    { expiresIn: process.env.TEMP_TOKEN_EXPIRES_IN || "10m" }
  );
}

export function signAccessToken(user) {
  return jwt.sign(
    { sub: user.user_id, role_id: user.role_id, type: "ACCESS" },
    process.env.JWT_ACCESS_SECRET,
    { expiresIn: process.env.ACCESS_TOKEN_EXPIRES_IN || "15m" }
  );
}

export function signRefreshToken(userId) {
  return jwt.sign(
    { sub: userId, type: "REFRESH" },
    process.env.JWT_REFRESH_SECRET,
    { expiresIn: process.env.REFRESH_TOKEN_EXPIRES_IN || "30d" }
  );
}
