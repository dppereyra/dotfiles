python-clean() {
    find . | grep -E "(__pycache__|\.pyc|\.pyo|\.egg-info$)" | xargs rm -rfv
    find . | grep -E "(\.log$|\__pypackages__|\.tox)" | xargs rm -rfv
    rm -Rf pip-wheel-metadata
}
