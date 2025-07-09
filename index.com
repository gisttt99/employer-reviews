<!DOCTYPE html>
<html lang="el">
<head>
  <meta charset="UTF-8">
  <title>Αξιολογήσεις Εργοδοτών</title>
  <style>
    body {
      font-family: Arial, sans-serif;
      background: #f4f4f4;
      margin: 0;
      padding: 0;
    }

    header {
      background-color: #6a0dad;
      padding: 15px 20px;
      color: white;
    }

    .logo {
      font-size: 24px;
      font-weight: bold;
    }

    h1 {
      text-align: center;
      color: #333;
      margin: 20px 0;
    }

    .container {
      max-width: 700px;
      margin: auto;
      padding: 20px;
    }

    .box {
      background: white;
      padding: 20px;
      margin-bottom: 20px;
      border-radius: 10px;
      box-shadow: 0 2px 5px rgba(0,0,0,0.1);
    }

    label {
      display: block;
      margin-top: 10px;
      font-weight: bold;
    }

    input, select, textarea {
      width: 100%;
      padding: 8px;
      margin-top: 5px;
      border-radius: 5px;
      border: 1px solid #ccc;
    }

    button {
      margin-top: 15px;
      padding: 10px 20px;
      background-color: #4CAF50;
      color: white;
      border: none;
      border-radius: 5px;
      cursor: pointer;
    }

    button:hover {
      background-color: #45a049;
    }

    .review {
      background: white;
      padding: 15px;
      border-radius: 10px;
      margin-bottom: 10px;
      box-shadow: 0 1px 3px rgba(0,0,0,0.1);
    }

    .stars {
      color: gold;
    }

    .delete-button {
      background-color: #e53935;
      color: white;
      border: none;
      padding: 5px 10px;
      border-radius: 4px;
      float: right;
      cursor: pointer;
    }

    .delete-button:hover {
      background-color: #c62828;
    }
  </style>
</head>
<body>

  <header>
    <div class="logo">+ERGASIA</div>
  </header>

  <h1>Αξιολογήσεις Εργοδοτών</h1>

  <div class="container">

    <!-- Προσθήκη νέας εταιρείας -->
    <div class="box">
      <h2>Νέα Εταιρεία</h2>
      <label for="newCompany">Όνομα Εταιρείας</label>
      <input id="newCompany" placeholder="Π.χ. Εταιρεία Χ">
      <button onclick="addCompany()">Προσθήκη</button>
    </div>

    <!-- Επιλογή εταιρείας και φίλτρα -->
    <div class="box">
      <h2>Επιλογή Εταιρείας</h2>
      <label for="company">Εταιρεία</label>
      <select id="company" onchange="showReviews()"></select>

      <label for="sector">Κλάδος</label>
      <input id="sector" placeholder="Π.χ. Πληροφορική">

      <label for="location">Τοποθεσία</label>
      <input id="location" placeholder="Π.χ. Αθήνα">

      <label for="size">Μέγεθος Εταιρείας</label>
      <select id="size">
        <option value="">Επιλέξτε</option>
        <option>Μικρή</option>
        <option>Μεσαία</option>
        <option>Μεγάλη</option>
      </select>
    </div>

    <!-- Υποβολή αξιολόγησης -->
    <div class="box">
      <h2>Γράψε Αξιολόγηση</h2>
      <label for="rating">Βαθμολογία (1-5)</label>
      <select id="rating">
        <option value="1">1 - Κακή</option>
        <option value="2">2 - Μέτρια</option>
        <option value="3">3 - Καλή</option>
        <option value="4">4 - Πολύ καλή</option>
        <option value="5">5 - Εξαιρετική</option>
      </select>

      <label for="comment">Σχόλιο</label>
      <textarea id="comment" rows="4" placeholder="Περιέγραψε την εμπειρία σου..."></textarea>

      <button onclick="submitReview()">Υποβολή</button>
    </div>

    <!-- Λίστα αξιολογήσεων -->
    <div class="box" id="reviewList">
      <h2>Αξιολογήσεις</h2>
    </div>

  </div>

  <script>
    const defaultCompanies = ["Εταιρεία Α", "Εταιρεία Β", "Εταιρεία Γ"];

    function loadCompanies() {
      const companySelect = document.getElementById("company");
      companySelect.innerHTML = "";
      const stored = JSON.parse(localStorage.getItem("companies") || "[]");
      const companies = [...new Set([...defaultCompanies, ...stored])];
      companies.forEach(name => {
        const opt = document.createElement("option");
        opt.value = name;
        opt.textContent = name;
        companySelect.appendChild(opt);
      });
    }

    function addCompany() {
      const name = document.getElementById("newCompany").value.trim();
      if (!name) return;
      const stored = JSON.parse(localStorage.getItem("companies") || "[]");
      if (!stored.includes(name)) {
        stored.push(name);
        localStorage.setItem("companies", JSON.stringify(stored));
        loadCompanies();
        document.getElementById("company").value = name;
        showReviews();
      }
      document.getElementById("newCompany").value = "";
    }

    function submitReview() {
      const company = document.getElementById("company").value;
      const rating = parseInt(document.getElementById("rating").value);
      const comment = document.getElementById("comment").value.trim();
      const sector = document.getElementById("sector").value.trim();
      const location = document.getElementById("location").value.trim();
      const size = document.getElementById("size").value;

      if (!comment) {
        alert("Το σχόλιο δεν μπορεί να είναι κενό.");
        return;
      }

      const review = {
        id: Date.now(),
        company,
        rating,
        comment,
        date: new Date().toLocaleDateString("el-GR"),
        sector,
        location,
        size
      };

      const reviews = JSON.parse(localStorage.getItem("reviews") || "[]");
      reviews.push(review);
      localStorage.setItem("reviews", JSON.stringify(reviews));
      document.getElementById("comment").value = "";
      showReviews();
    }

    function deleteReview(id) {
      let reviews = JSON.parse(localStorage.getItem("reviews") || "[]");
      reviews = reviews.filter(r => r.id !== id);
      localStorage.setItem("reviews", JSON.stringify(reviews));
      showReviews();
    }

    function showReviews() {
      const company = document.getElementById("company").value;
      const reviews = JSON.parse(localStorage.getItem("reviews") || "[]");
      const filtered = reviews.filter(r => r.company === company);
      const list = document.getElementById("reviewList");

      list.innerHTML = `<h2>Αξιολογήσεις</h2>`;

      if (filtered.length === 0) {
        list.innerHTML += "<p>Δεν υπάρχουν αξιολογήσεις για αυτήν την εταιρεία.</p>";
        return;
      }

      const avg = (filtered.reduce((a, b) => a + b.rating, 0) / filtered.length).toFixed(1);
      list.innerHTML += `<p>Μέση βαθμολογία: <strong>${avg}</strong> ⭐</p>`;

      filtered.reverse().forEach(r => {
        const div = document.createElement("div");
        div.className = "review";
        div.innerHTML = `
          <button class="delete-button" onclick="deleteReview(${r.id})">Διαγραφή</button>
          <div class="stars">Βαθμολογία: ${"★".repeat(r.rating)}${"☆".repeat(5 - r.rating)}</div>
          <p>${r.comment}</p>
          <small>Ημερομηνία: ${r.date}</small><br>
          ${r.sector ? `<small>Κλάδος: ${r.sector}</small><br>` : ""}
          ${r.location ? `<small>Τοποθεσία: ${r.location}</small><br>` : ""}
          ${r.size ? `<small>Μέγεθος: ${r.size}</small>` : ""}
        `;
        list.appendChild(div);
      });
    }

    loadCompanies();
    showReviews();
  </script>

</body>
</html>
