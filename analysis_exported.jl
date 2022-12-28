using Pkg
# Pkg.add("DataFrames")
# Pkg.add("CSV")
# Pkg.add("Plots")
# Pkg.add("Statistics")
# Pkg.add("FreqTables")
using DataFrames
using Plots
using Statistics
using CSV
using Dates
using FreqTables

df = DataFrame(CSV.File("transactions_cleaned.csv"))

println("Minimum: ", minimum(df.Amount), "\nMaximum: ", maximum(df.Amount), "\nMean: ", mean(df.Amount), "\nMedian: ", median(df.Amount))

# plot histogram over time
Plots.histogram(df.Amount, bins=100, title="Histogram of Amounts", xlabel="Amount", ylabel="Frequency")

# convert Date column to DateTime
df.Date = Date.(df.Date, "m/d/y")

# remove rows if they have B, C, W, A as they are debit accounts
df = filter!(row -> !(row.Account_Name in ["B", "C", "W", "A"]), df)


# remove rows if they have the category "Credit Card Payment"
df = filter!(row -> !(row.Category in ["Credit Card Payment", "Deposit", "Paycheck"]), df)

# sort dateframe by amount 
sort(df, :Amount, rev=true)

# categorical plot by category
Plots.scatter(df.Date, df.Amount, group=df.Category, title="Amounts by Category", xlabel="Date", ylabel="Amount", legend=:left)

# plot by account
Plots.scatter(df.Date, df.Amount, group=df.Account_Name, title="Amounts by Account", xlabel="Date", ylabel="Amount", legend=:left)

# calculate outliers 
q1 = quantile(df.Amount, 0.25)
q3 = quantile(df.Amount, 0.75)
iqr = q3 - q1
lower = q1 - 1.5 * iqr
upper = q3 + 1.5 * iqr
println("Lower: ", lower, "\nUpper: ", upper)

# remove outliers
df = filter(row -> row.Amount > lower, df)


df = filter(row -> row.Amount < upper, df)
# plot scatterplot 
Plots.scatter(df.Date, df.Amount, group=df.Category, title="Amounts by Category", xlabel="Date", ylabel="Amount", legend=:left)


binwidth = 2 * iqr * length(df.Amount)^(-1 / 3) # calculate binwidth, 2*iqr*n^(-1/3) using Freedman–Diaconis rule

# plot histogram
Plots.histogram(df.Amount, bins=trunc(Int64, binwidth), title="Histogram of Amounts", xlabel="Amount", ylabel="Frequency")

# sort df by Date
sort(df, :Date)

df_before_october_3rd = filter(row -> row.Date < Date(2022, 10, 3), df)
df_after_october_3rd = filter(row -> row.Date >= Date(2022, 10, 3), df)


println(freqtable(df_before_october_3rd.Category))
println(freqtable(df_after_october_3rd.Category))

#  i know :( it looks ugly but it works
b4 = []
categories = ["Food_Dining", "Shopping", "Public_Transportation", "Health_Fitness", "Investments", "Travel", "Auto_Transport", "Bills_Utilities", "Education", "Food_Delivery", "Entertainment", "Business_Services"]
for i in 1:length(categories)
    push!(b4, sum(filter(row -> occursin(categories[i], row.Category), df_before_october_3rd).Amount))
end

aft = []
for i in 1:length(categories)
    push!(aft, sum(filter(row -> occursin(categories[i], row.Category), df_after_october_3rd).Amount))
end

differences = [] 
for i in 1:12
    push!(differences, aft[i] - b4[i])
end

# plot bar graph,put a legend on the bar graph
Plots.bar(["F&D", "SH", "PT", "H&F", "INV", "Travel", "AT", "B&U", "EDU", "FOOD", "ENT.", "BS"], differences, title="Differences in Spending", xlabel="Category", ylabel="Difference in Spending", legend=:topleft)

for i in 1:12
    if differences[i] > 0
        print("You spent more. Amount spent: ", round(differences[i]), " dollars, ")
        print("Category: ", categories[i], " \n")
    else
        print("You spent less. Amount spent: ", round(differences[i]), " dollars, ")
        print("Category: ", categories[i], " \n")
    end
end

