const express = require("express");
const cors = require("cors");

const app = express();
app.use(cors());
app.use(express.json());

// ทดสอบว่าเซิร์ฟเวอร์ทำงานไหม
app.get("/", (req, res) => {
  res.send("Backend is running...");
});

// API แนะนำอาหาร
app.post("/recommend", (req, res) => {
  const { age, weight, goal } = req.body;

  let food = "Rice & Chicken";

  if (goal === "lose") food = "Salad & Boiled Egg";
  if (goal === "gain") food = "Steak & Rice";

  res.json({
    success: true,
    recommendation: food
  });
});

const PORT = 3000;
app.listen(PORT, () => {
  console.log(`Server running at http://localhost:${PORT}`);
});