# SSURGO Data Snapshots

This repository generates monthly snapshots of SSURGO and related soil data from various sources, including the USDA Soil Data Access (SDA) web service. The initial proof of concept is a lookup table mapping MUKEY to NATIONALMUSYM, which can be used to augment data downloaded from Web Soil Survey that do not contain the `nationalmusym` column in `mapunit` or `mupolygon` tables.

## Usage

The main function is `create_nationalmusym_lookup()` which generates a snapshot for the current fiscal year.

To load data from past fiscal years: `get_nationalmusym_lookup(fy = 2026)`

## GitHub Actions

Runs monthly on the 1st, or manually via dispatch. Creates releases tagged by FY with artifacts.

## Installation

```r
devtools::install_github("brownag/SSURGOsnapshots")
```

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) for details on adding new snapshots and the package structure.

## License

CC0