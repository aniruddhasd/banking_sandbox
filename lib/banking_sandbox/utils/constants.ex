defmodule BankingSandbox.Utils.Constants do
    
    def spend_types, do: ["Mortgage or rent","Property taxes","Household repairs","HOA fees","Car payment","Car warranty","Gas","Tires","Maintenance and oil changes","Parking fees","Repairs","Registration and DMV Fees","Groceries","Restaurants","Pet food","Electricity","Water","Garbage","Phones","Cable","Internet","Adults’ clothing","Adults’ shoes","Children’s clothing","Children’s shoes","Primary care","Dental care","Specialty care (dermatologists, orthodontics, optometrists, etc.)","Urgent care","Medications","Medical devices","Health insurance","Homeowner’s or renter’s insurance","Home warranty or protection plan","Auto insurance","Life insurance","Disability insurance","Toiletries","Laundry detergent","Dishwasher detergent","Cleaning supplies","Tools","Gym memberships","Haircuts","Salon services","Cosmetics (like makeup or services like laser hair removal)","Babysitter","Subscriptions","Personal loans","Student loans","Credit cards","Financial planning","Investing","Children’s college","Your college","School supplies","Books","Emergency fund","Big purchases like a new mattress or laptop","Other savings","Birthday","Anniversary","Wedding","Christmas","Special occasion","Charities","Alcohol and/or bars","Games","Movies","Concerts","Vacations","Subscriptions (Netflix, Amazon, Hulu, etc.)"]
    def first_names, do: ["Owen","Wyatt","John","Jack","Luke","Jayden","Dylan","Grayson","Levi","Isaac","Gabriel","Julian","Mateo","Anthony","Jaxon","Lincoln","Joshua","Christopher","Andrew"]
    def last_names, do: ["Miller","Davis","Rodriguez","Martinez","Hernandez","Lopez","Gonzalez","Wilson","Anderson","Thomas","Taylor","Moore","Jackson"]
    def epoch, do: %{date: ~D[2020-01-01], unix_time: DateTime.utc_now |> DateTime.to_unix}
    def deposit_types, do: ["Salary", "Dividend", "Interest Deposit", "Cash Deposit"]
    def transaction_types_debit, do: ["card_payment", "cash", "cheque", "tax"]
    def transaction_types_credit, do: [ "cash", "cheque"]

    def customer_call_initial, do: 10
    def customer_call_standard_limit, do: 60
    def customer_call_standard, do: 10_000
    def account_call, do: 10_000
    def transaction_call_initial, do: 2000
    def transaction_call_standard, do: 1000
    
end