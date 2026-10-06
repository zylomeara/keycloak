# Official Keycloak 26.8.0 with keycloak/keycloak#53261 fixed: offline token refresh keeps
# the resource indicator. Only the keycloak-services jar differs (see build.sh).
FROM quay.io/keycloak/keycloak:26.8.0@sha256:b0f60d489d51c5d113390bdf5461d4c06e6051be026c05549f2e1e10ec352bcc
COPY --chown=keycloak:root org.keycloak.keycloak-services-26.8.0.jar /opt/keycloak/lib/lib/main/org.keycloak.keycloak-services-26.8.0.jar
