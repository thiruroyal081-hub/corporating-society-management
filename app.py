from flask import Flask, render_template, request, redirect, url_for, flash
from datetime import date

app = Flask(__name__)
# Development-only secret. Set FLASK_SECRET_KEY in the environment before deployment.
app.config["SECRET_KEY"] = "dev-only-change-before-deployment"

# Demo-only in-memory data. It resets when the server restarts.
# Replace with validated database operations before real use.
members = [
    {
        "member_id": "MEM-0001",
        "full_name": "Demo Member",
        "mobile": "0000000000",
        "join_date": "2026-01-01",
        "status": "Active",
    }
]


@app.get("/")
def dashboard():
    return render_template("dashboard.html", member_count=len(members))


@app.get("/members")
def member_list():
    query = request.args.get("q", "").strip().lower()
    filtered = [
        member for member in members
        if query in member["member_id"].lower()
        or query in member["full_name"].lower()
        or query in member["mobile"].lower()
    ]
    return render_template("members.html", members=filtered, query=query)


@app.post("/members")
def add_member():
    full_name = request.form.get("full_name", "").strip()
    mobile = request.form.get("mobile", "").strip()
    join_date = request.form.get("join_date", "").strip() or date.today().isoformat()

    if not full_name:
        flash("Full name is required.", "error")
        return redirect(url_for("member_list"))

    if mobile and (not mobile.isdigit() or len(mobile) != 10):
        flash("Enter a 10-digit mobile number or leave it blank.", "error")
        return redirect(url_for("member_list"))

    next_number = len(members) + 1
    member_id = f"MEM-{next_number:04d}"
    members.append({
        "member_id": member_id,
        "full_name": full_name,
        "mobile": mobile,
        "join_date": join_date,
        "status": "Active",
    })
    flash(f"Demo member {member_id} added. This record is temporary and will reset when the app restarts.", "success")
    return redirect(url_for("member_list"))


@app.get("/health")
def health():
    return {"status": "ok", "mode": "development-demo"}


if __name__ == "__main__":
    # Debug mode is for local development only. Do not expose this server publicly.
    app.run(host="127.0.0.1", port=5000, debug=True)
