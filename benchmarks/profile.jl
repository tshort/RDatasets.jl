# Load packages
using Base

load("DataFrames")
using DataFrames

load("RDatasets")

# Test on all of the datasets from RDatasets
datasets = RDatasets.datasets()

# Keep track of the performance of read_table as TableTime and
#  of csvDataFrame as CSVTime
performance = DataFrame({ASCIIString, Float64, Float64},
                        ["Filename", "TableTime", "CSVTime"],
                        length(datasets))

# Compute R's performance on the same data sets
run(`Rscript read_datasets.R`)

# Force compilation of both reader functions while pulling
#  in R performance data
r_performance = read_table(file_path("results", "R_performance.csv"))
r_performance = csvDataFrame(file_path("results", "R_performance.csv"))

# Keep a record of the location of all data sets
require("pkg")
package_directory = file_path(Pkg.package_directory("RDatasets"), "data")

# Loop over datasets and store performance in a Julian DataFrame
i = 0
for dataset in datasets
  i += 1

  directory, dataname = dataset[1], dataset[2]
  filename = file_path(package_directory, directory, strcat(dataname, ".csv"))
  performance[i, "Filename"] = filename

  # Try out the different readers
  try
    performance[i, "TableTime"] = @elapsed read_table(filename)
  end
  try
    performance[i, "CSVTime"] = @elapsed csvDataFrame(filename)
  end
end

# Merge in R's performance information
performance["RCSVTime"] = r_performance["RCSVTime"]

# Write statistics to disk for visualization in R
DataFrames.write_table(performance, file_path("results", "performance.tsv"))

# How often do the readers fail to read a dataset?
length(find(isna(performance["TableTime"])))
length(find(isna(performance["CSVTime"])))
length(find(isna(performance["RCSVTime"])))
