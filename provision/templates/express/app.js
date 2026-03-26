const express = require("express");
const app = express();
const port = process.env.PORT || 8001;

app.get("/", (req, res) => res.json({ status: "ok", framework: "express" }));

app.listen(port, "0.0.0.0", () => console.log(`Listening on :${port}`));
