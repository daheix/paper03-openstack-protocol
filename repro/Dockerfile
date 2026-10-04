# P03 L2 reproducible package — single locked environment (protocol rule 11).
# Base image version-pinned; digest to be filled from `docker images --digests`
# after the first `docker pull` on a docker-capable host (none available in the
# build environment at package-creation time — honest TODO, see repro/README.md).
FROM python:3.12.3-slim-bookworm

# Minimal system deps: libblas3 (getdp runtime), make (verify driver).
RUN apt-get update \
 && apt-get install -y --no-install-recommends libblas3 make \
 && rm -rf /var/lib/apt/lists/*

WORKDIR /p03

# Python layer — exact pins only (requirements.lock from clean-venv pip freeze).
COPY repro/requirements.lock /tmp/requirements.lock
RUN pip install --no-cache-dir -r /tmp/requirements.lock

# Bundled solvers (self-contained binaries, 0 missing shared libs on glibc).
COPY repro/third_party/ /p03/bin/third_party/
ENV PATH="/p03/bin/third_party/gmsh/bin:/p03/bin/third_party/getdp/bin:${PATH}"

# Frozen engine snapshot + driver scripts + stratified sample + model library.
COPY engine/ /p03/engine/
COPY scripts/ /p03/scripts/
COPY data/sample30_v3.json /p03/data/sample30_v3.json
COPY repro/model_library/ /p03/repro/model_library/
COPY repro/expected_results/ /p03/expected_results/

# run_emag_getdp.py resolves solver via repo-relative bin/third_party or PATH.
CMD ["make", "-C", "/p03", "verify"]
