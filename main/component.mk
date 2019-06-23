#
# "main" pseudo-component makefile.
#
# (Uses default behaviour of compiling all source files in directory, adding 'include' to include path.)

COMPONENT_SRCDIRS += ${PROJECT_PATH}/myCA

COMPONENT_EMBED_TXTFILES :=  ${PROJECT_PATH}/myCA/certs/ca.cer ${PROJECT_PATH}/myCA/certs/esp_client.cer ${PROJECT_PATH}/myCA/private/esp_client.key

