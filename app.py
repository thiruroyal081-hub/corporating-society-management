import os
from datetime import date
from decimal import Decimal, InvalidOperation

from flask import Flask, render_template, request, redirect, url_for, flash

app = Flask(__name__)
app.config["SECRET_KEY"] = os.environ.get("FLASK_SECRET_KEY", "local-development-only-change-me")

# DEVELOPMENT ONLY: all records below are temporary in-memory demo data.
# They reset when the server restarts. Do not use for real member accounts or transactions.
members = [
    {"member_id": "MEM-0001", "full_name": "Demo Member", "mobile": "", "join_date": "2026-01-01", "status": "Active"}
]
loans = []
deposits = []
recoveries = []


def money(value, label="Amount"):
    try:
        amount = Decimal(value or "0")
    except InvalidOperation:
        raise ValueError(f"{label} must be a valid number.")
    if not amount.is_finite() or amount < 0:
        raise ValueError(f"{label} cannot be negative.")
    if amount > Decimal("9999999999.99"):
        raise ValueError(f"{label} is too large.")
    return amount.quantize(Decimal("0.01"))


def find_member(member_id):
    return next((m for m in members if m["member_id"] == member_id), None)


@app.get("/")
def dashboard():
    return render_template(
        "dashboard.html",
        member_count=len(members),
        loan_count=len(loans),
        deposit_count=len(deposits),
        recovery_count=len(recoveries),
    )


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
    try:
        date.fromisoformat(join_date)
    except ValueError:
        flash("Enter a valid joining date.", "error")
        return redirect(url_for("member_list"))
    member_id = f"MEM-{max([int(m['member_id'].split('-')[1]) for m in members] + [0]) + 1:04d}"
    members.append({"member_id": member_id, "full_name": full_name, "mobile": mobile, "join_date": join_date, "status": "Active"})
    flash(f"Demo member {member_id} added. This record is temporary.", "success")
    return redirect(url_for("member_list"))


@app.route("/loans", methods=["GET", "POST"])
def loan_list():
    if request.method == "POST":
        member_id = request.form.get("member_id", "").strip()
        loan_type = request.form.get("loan_type", "").strip()
        try:
            principal = money(request.form.get("principal"), "Principal")
            rate = money(request.form.get("rate"), "Annual interest rate")
            months = int(request.form.get("months", "0"))
            if not find_member(member_id):
                raise ValueError("Select a valid member ID from the member register.")
            if loan_type not in {"Short term", "Medium term", "Long term"}:
                raise ValueError("Select a valid loan type.")
            if principal <= 0 or months < 1 or months > 600 or rate > 100:
                raise ValueError("Principal must be positive, months 1–600, and rate no more than 100%.")
        except (ValueError, InvalidOperation) as exc:
            flash(str(exc), "error")
            return redirect(url_for("loan_list"))
        loans.append({"loan_id": f"LN-{len(loans)+1:04d}", "member_id": member_id, "member_name": find_member(member_id)["full_name"], "loan_type": loan_type, "principal": str(principal), "rate": str(rate), "months": months, "date": date.today().isoformat(), "status": "Draft"})
        flash("Demo loan record saved as DRAFT. Interest, fees and sanction accounting are not calculated.", "success")
        return redirect(url_for("loan_list"))
    return render_template("loans.html", loans=loans, members=members)


@app.route("/deposits", methods=["GET", "POST"])
def deposit_list():
    if request.method == "POST":
        member_id = request.form.get("member_id", "").strip()
        deposit_type = request.form.get("deposit_type", "").strip()
        try:
            amount = money(request.form.get("amount"), "Deposit amount")
            rate = money(request.form.get("rate"), "Annual interest rate")
            if not find_member(member_id):
                raise ValueError("Select a valid member ID from the member register.")
            if deposit_type not in {"Thrift", "Recurring Deposit (RD)", "Fixed Deposit (FD)", "Benevolent Fund", "Family Welfare Fund"}:
                raise ValueError("Select a valid deposit or fund type.")
            if amount <= 0 or rate > 100:
                raise ValueError("Amount must be positive and rate no more than 100%.")
        except (ValueError, InvalidOperation) as exc:
            flash(str(exc), "error")
            return redirect(url_for("deposit_list"))
        deposits.append({"deposit_id": f"DP-{len(deposits)+1:04d}", "member_id": member_id, "member_name": find_member(member_id)["full_name"], "deposit_type": deposit_type, "amount": str(amount), "rate": str(rate), "date": date.today().isoformat(), "status": "Draft"})
        flash("Demo deposit/fund record saved as DRAFT. Interest and benefit rules are not applied.", "success")
        return redirect(url_for("deposit_list"))
    return render_template("deposits.html", deposits=deposits, members=members)


@app.route("/recovery", methods=["GET", "POST"])
def recovery_list():
    if request.method == "POST":
        member_id = request.form.get("member_id", "").strip()
        month = request.form.get("month", "").strip()
        try:
            date.fromisoformat(month + "-01")
            amount = money(request.form.get("amount"), "Recovery amount")
            if not find_member(member_id):
                raise ValueError("Select a valid member ID from the member register.")
            if amount <= 0:
                raise ValueError("Recovery amount must be greater than zero.")
        except (ValueError, InvalidOperation) as exc:
            flash(str(exc), "error")
            return redirect(url_for("recovery_list"))
        recoveries.append({"receipt_id": f"RC-{len(recoveries)+1:04d}", "member_id": member_id, "member_name": find_member(member_id)["full_name"], "month": month, "amount": str(amount), "date": date.today().isoformat(), "status": "Draft"})
        flash("Demo recovery saved as DRAFT only. No loan/deposit balances or accounts were updated.", "success")
        return redirect(url_for("recovery_list"))
    return render_template("recovery.html", recoveries=recoveries, members=members)


@app.get("/reports")
def reports():
    total_loan_principal = sum((Decimal(x["principal"]) for x in loans), Decimal("0.00"))
    total_deposits = sum((Decimal(x["amount"]) for x in deposits), Decimal("0.00"))
    total_recoveries = sum((Decimal(x["amount"]) for x in recoveries), Decimal("0.00"))
    return render_template("reports.html", member_count=len(members), loans=loans, deposits=deposits, recoveries=recoveries, total_loan_principal=total_loan_principal, total_deposits=total_deposits, total_recoveries=total_recoveries)


@app.get("/health")
def health():
    return {"status": "ok", "mode": "development-demo", "persistent_storage": False}


if __name__ == "__main__":
    # Suitable for local development or a temporary demo deployment only.
    # Persistent storage and authentication must be added before real use.
    port = int(os.environ.get("PORT", "5000"))
    app.run(host="0.0.0.0", port=port, debug=os.environ.get("FLASK_DEBUG") == "1")
