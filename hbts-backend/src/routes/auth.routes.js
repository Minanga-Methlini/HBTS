import { Router } from "express";
import {
  passengerSignup,
  passengerVerifySignupOtp,
} from "../controllers/auth.controller.js";
import { passengerLogin, passengerVerifyLoginOtp } from "../controllers/auth.controller.js";
import { requireTempToken } from "../middleware/tempAuth.js";


const router = Router();

router.post("/passenger/signup", passengerSignup);
router.post("/passenger/signup/verify-otp", passengerVerifySignupOtp);
router.post("/passenger/login", passengerLogin);
router.post("/passenger/login/verify-otp", requireTempToken, passengerVerifyLoginOtp);


export default router;
