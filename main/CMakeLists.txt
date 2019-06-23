set(COMPONENT_SRCS "advanced_https_ota_example.c")
set(COMPONENT_ADD_INCLUDEDIRS ".")


# Embed the server root certificate into the final binary
idf_build_get_property(project_dir PROJECT_DIR)
set(COMPONENT_EMBED_TXTFILES ${project_dir}/myCA/certs/ca.cer ${project_dir}/myCA/certs/esp_client.cer ${project_dir}/myCA/private/esp_client.key)

register_component()
