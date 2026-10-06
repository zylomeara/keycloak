#!/usr/bin/env bash
# Build keycloak-services jar with the #53261 fix on top of the official 26.8.0 image.
# Only TokenManager*.class change; everything else is the official binary.
# Usage: deploy/fix53261/build.sh <out-dir>   (needs docker; run from the repo root)
set -euo pipefail

BASE_IMAGE=quay.io/keycloak/keycloak:26.8.0@sha256:b0f60d489d51c5d113390bdf5461d4c06e6051be026c05549f2e1e10ec352bcc
JDK_IMAGE=eclipse-temurin:21-jdk
JAR=org.keycloak.keycloak-services-26.8.0.jar
SRC=services/src/main/java/org/keycloak/protocol/oidc/TokenManager.java

out=$(cd "${1:?out dir}" && pwd)
work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT

cid=$(docker create "$BASE_IMAGE")
docker cp "$cid:/opt/keycloak/lib" "$work/lib" >/dev/null
docker rm "$cid" >/dev/null
cp "$SRC" "$work/TokenManager.java"
cp "$work/lib/lib/main/$JAR" "$work/$JAR"

# Upstream compiles keycloak-services for Java 17 (class major 61); keep that.
docker run --rm -v "$work:/w" -w /w "$JDK_IMAGE" sh -euc "
  mkdir out
  javac --release 17 -nowarn -proc:none -encoding UTF-8 \
    -cp 'lib/lib/main/*:lib/lib/boot/*:lib/quarkus/*:lib/app/*' -d out TokenManager.java
  cd out && jar uf ../$JAR org/keycloak/protocol/oidc/TokenManager*.class
"

python3 -I - "$work/lib/lib/main/$JAR" "$work/$JAR" <<'EOF'
import hashlib, sys, zipfile
a, b = (zipfile.ZipFile(p) for p in sys.argv[1:])
assert set(a.namelist()) == set(b.namelist()), "jar entries differ"
changed = sorted(n for n in a.namelist() if hashlib.sha256(a.read(n)).digest() != hashlib.sha256(b.read(n)).digest())
assert changed and all(n.startswith("org/keycloak/protocol/oidc/TokenManager") for n in changed), changed
print(f"ok: {len(changed)} TokenManager classes replaced, {len(a.namelist()) - len(changed)} entries unchanged")
EOF

cp "$work/$JAR" "$out/$JAR"
cp "$(dirname "$0")/Dockerfile" "$out/Dockerfile"
shasum -a 256 "$out/$JAR"
