import { Request, Response, NextFunction } from "express";
import { verifyToken, TokenPayload } from "./jwt";

export interface AuthedRequest extends Request {
  auth?: TokenPayload;
}

export function requireAuth(req: AuthedRequest, res: Response, next: NextFunction) {
  const header = req.headers.authorization;
  if (!header || !header.startsWith("Bearer ")) {
    return res.status(401).json({ error: "token ausente" });
  }
  try {
    req.auth = verifyToken(header.slice("Bearer ".length));
    next();
  } catch {
    return res.status(401).json({ error: "token inválido ou expirado" });
  }
}
