# Distributed under the OSI-approved BSD 3-Clause License.
# See accompanying file LICENSE-BSD for details.

cmake_minimum_required(VERSION 3.25)
get_filename_component(SCRIPT_NAME "${CMAKE_CURRENT_LIST_FILE}" NAME_WE)
set(CMAKE_MESSAGE_INDENT "[${VERSION}][${LANGUAGE}] ")
set(CMAKE_MESSAGE_INDENT_BACKUP "${CMAKE_MESSAGE_INDENT}")
message(STATUS "-------------------- ${SCRIPT_NAME} --------------------")


set(CMAKE_MODULE_PATH   "${PROJ_CMAKE_MODULES_DIR}")
set(CMAKE_PROGRAM_PATH  "${PROJ_CONDA_DIR}"
                        "${PROJ_CONDA_DIR}/Library")
find_package(Git        MODULE REQUIRED)
find_package(Gettext    MODULE REQUIRED COMPONENTS Msgcat Msgmerge)
find_package(Python     MODULE REQUIRED COMPONENTS Interpreter)
find_package(Sphinx     MODULE REQUIRED COMPONENTS Build)
include(LogUtils)
include(GitUtils)
include(JsonUtils)
include(GettextUtils)


message(STATUS "Determining whether it is required to update .pot files...")
file(READ "${REFERENCES_JSON_PATH}" REFERENCES_JSON_CNT)
get_reference_of_latest_from_repo_and_current_from_json(
    IN_JSON_CNT                     "${REFERENCES_JSON_CNT}"
    IN_LOCAL_PATH                   "${PROJ_OUT_REPO_DIR}"
    IN_VERSION_TYPE                 "${VERSION_TYPE}"
    IN_BRANCH_NAME                  "${BRANCH_NAME}"
    IN_TAG_PATTERN                  "${TAG_PATTERN}"
    IN_TAG_SUFFIX                   "${TAG_SUFFIX}"
    IN_DOT_NOTATION                 ".pot"
    OUT_LATEST_OBJECT               LATEST_POT_OBJECT
    OUT_LATEST_REFERENCE            LATEST_POT_REFERENCE
    OUT_CURRENT_OBJECT              CURRENT_POT_OBJECT
    OUT_CURRENT_REFERENCE           CURRENT_POT_REFERENCE)
if (MODE_OF_UPDATE STREQUAL "COMPARE")
    if (NOT CURRENT_POT_REFERENCE STREQUAL LATEST_POT_REFERENCE)
        set(UPDATE_POT_REQUIRED     ON)
    else()
        set(UPDATE_POT_REQUIRED     OFF)
    endif()
elseif (MODE_OF_UPDATE STREQUAL "ALWAYS")
    set(UPDATE_POT_REQUIRED         ON)
elseif (MODE_OF_UPDATE STREQUAL "NEVER")
    if (NOT CURRENT_POT_REFERENCE)
        set(UPDATE_POT_REQUIRED     ON)
    else()
        set(UPDATE_POT_REQUIRED     OFF)
    endif()
else()
    message(FATAL_ERROR "Invalid MODE_OF_UPDATE value. (${MODE_OF_UPDATE})")
endif()
remove_cmake_message_indent()
message("")
message("LATEST_POT_OBJECT      = ${LATEST_POT_OBJECT}")
message("CURRENT_POT_OBJECT     = ${CURRENT_POT_OBJECT}")
message("LATEST_POT_REFERENCE   = ${LATEST_POT_REFERENCE}")
message("CURRENT_POT_REFERENCE  = ${CURRENT_POT_REFERENCE}")
message("MODE_OF_UPDATE         = ${MODE_OF_UPDATE}")
message("UPDATE_POT_REQUIRED    = ${UPDATE_POT_REQUIRED}")
message("")
restore_cmake_message_indent()


#[============================================================[
# Add 'gettextdocs' target in 'Makefile' file.
# Add 'gettextdocs' target in 'Documentation/Makefile' file.
# Add 'gettext'     target in 'Documentation/userspace-api/media/Makefile' file.
# Add 'locale' into 'exclude_pattern' list in 'Documentation/conf.py' file.
# Remove 'translations' from 'extensions' list in 'Documentation/conf.py' file.
# Remove 'Translations' section in 'Documentation/index.rst' file.
# Remove directory 'Documentation/translations/'.
#]============================================================]


set(REPO_MAKEFILE_FILE          "${PROJ_OUT_REPO_DIR}/Makefile")
set(DOCS_MAKEFILE_FILE          "${PROJ_OUT_REPO_DIR}/Documentation/Makefile")
set(DOCS_MEDIA_MAKEFILE_FILE    "${PROJ_OUT_REPO_DIR}/Documentation/userspace-api/media/Makefile")
set(DOCS_CONF_PY_FILE           "${PROJ_OUT_REPO_DIR}/Documentation/conf.py")
set(DOCS_INDEX_RST_FILE         "${PROJ_OUT_REPO_DIR}/Documentation/index.rst")
set(DOCS_TRANSLATION_DIR        "${PROJ_OUT_REPO_DIR}/Documentation/translations")


message(STATUS "Adding 'gettextdocs' target in 'Makefile' file...")
file(READ "${REPO_MAKEFILE_FILE}" ROOT_MAKEFILE_CNT)
string(FIND "${ROOT_MAKEFILE_CNT}" "DOC_TARGETS := gettextdocs" POSITION)
if (POSITION EQUAL -1)
    string(REGEX REPLACE "(DOC_TARGETS[ ]*:=[ ]*)(.*)[^\n]*" "\\1gettextdocs \\2" ROOT_MAKEFILE_CNT "${ROOT_MAKEFILE_CNT}")
    file(WRITE "${REPO_MAKEFILE_FILE}" "${ROOT_MAKEFILE_CNT}")
    remove_cmake_message_indent()
    message("")
    message("Added 'gettextdocs' target in 'Makefile' file.")
    message("File: ${REPO_MAKEFILE_FILE}")
    message("")
    restore_cmake_message_indent()
else()
    remove_cmake_message_indent()
    message("")
    message("No need to add 'gettextdocs' target in 'Makefile' file.")
    message("File: ${REPO_MAKEFILE_FILE}")
    message("")
    restore_cmake_message_indent()
endif()


message(STATUS "Adding 'gettextdocs' target in 'Documentation/Makefile' file...")
file(READ "${DOCS_MAKEFILE_FILE}" DOCS_MAKEFILE_CNT)
string(FIND "${DOCS_MAKEFILE_CNT}" "gettextdocs: \$(YNL_INDEX)" POSITION)
if (POSITION EQUAL -1)
    string(APPEND GETTEXTDOCS_CNT "\n")
    string(APPEND GETTEXTDOCS_CNT "gettextdocs: $(YNL_INDEX)\n")
    string(APPEND GETTEXTDOCS_CNT "\t@$(srctree)/scripts/sphinx-pre-install --version-check\n")
    string(APPEND GETTEXTDOCS_CNT "\t@+$(foreach var,$(SPHINXDIRS),$(call loop_cmd,sphinx,gettext,$(var),,$(var)))\n")
    string(APPEND DOCS_MAKEFILE_CNT "${GETTEXTDOCS_CNT}")
    file(WRITE "${DOCS_MAKEFILE_FILE}" "${DOCS_MAKEFILE_CNT}")
    remove_cmake_message_indent()
    message("")
    message("Added 'gettext' target in 'Documentation/Makefile' file.")
    message("File: ${DOCS_MAKEFILE_FILE}")
    message("")
    message("[GETTEXTDOCS_CNT_BEGIN]")
    message("${GETTEXTDOCS_CNT}")
    message("[GETTEXTDOCS_CNT_END]")
    message("")
    restore_cmake_message_indent()
else()
    remove_cmake_message_indent()
    message("")
    message("No need to add 'gettext' target in 'Documentation/Makefile' file.")
    message("File: ${DOCS_MAKEFILE_FILE}")
    message("")
    restore_cmake_message_indent()
endif()


message(STATUS "Adding 'gettext' target in 'Documentation/userspace-api/media/Makefile' file...")
file(READ "${DOCS_MEDIA_MAKEFILE_FILE}" DOCS_MEDIA_MAKEFILE_CNT)
string(FIND "${DOCS_MEDIA_MAKEFILE_CNT}" ".PHONY: gettext" POSITION)
if (POSITION EQUAL -1)
    string(REGEX REPLACE "(.PHONY:[ ]*)(.*)[^\n]*" "\\1gettext \\2" DOCS_MEDIA_MAKEFILE_CNT "${DOCS_MEDIA_MAKEFILE_CNT}")
endif()
string(FIND "${DOCS_MEDIA_MAKEFILE_CNT}" "gettext: all" POSITION)
if (POSITION EQUAL -1)
    set(SEARCH_PATTERN "(all: [$][(]IMGDOT[)] [$][(]BUILDDIR[)] [$][{]TARGETS[}]\n)")
    set(INSERT_CONTENT "gettext: all\n")
    string(REGEX REPLACE "${SEARCH_PATTERN}" "\\1${INSERT_CONTENT}" DOCS_MEDIA_MAKEFILE_CNT "${DOCS_MEDIA_MAKEFILE_CNT}")
    file(WRITE "${DOCS_MEDIA_MAKEFILE_FILE}" "${DOCS_MEDIA_MAKEFILE_CNT}")
    remove_cmake_message_indent()
    message("")
    message("Added 'gettext' target in 'Documentation/userspace-api/media/Makefile' file.")
    message("File: ${DOCS_MEDIA_MAKEFILE_FILE}")
    message("")
    restore_cmake_message_indent()
else()
    remove_cmake_message_indent()
    message("")
    message("No need to add 'gettext' target in 'Documentation/userspace-api/media/Makefile' file.")
    message("File: ${DOCS_MEDIA_MAKEFILE_FILE}")
    message("")
    restore_cmake_message_indent()
endif()


message(STATUS "Adding 'locale' into 'exclude_patterns' list in 'Documentation/conf.py' file...")
file(READ "${DOCS_CONF_PY_FILE}" DOCS_CONF_PY_CNT)
set(EXCLUDE_PATTERNS_REGEX "(exclude_patterns[ ]*=[ ]*[\[])([^\]]*[\]])")
string(REGEX MATCH "${EXCLUDE_PATTERNS_REGEX}" OLD_EXCLUDE_PATTERNS_LIST "${DOCS_CONF_PY_CNT}")
if (OLD_EXCLUDE_PATTERNS_LIST AND
    NOT OLD_EXCLUDE_PATTERNS_LIST MATCHES "\"locale\"")
    string(REGEX REPLACE "${EXCLUDE_PATTERNS_REGEX}" "\\1\"locale\",\\2" NEW_EXCLUDE_PATTERNS_LIST "${OLD_EXCLUDE_PATTERNS_LIST}")
    string(REGEX REPLACE "${EXCLUDE_PATTERNS_REGEX}" "${NEW_EXCLUDE_PATTERNS_LIST}" DOCS_CONF_PY_CNT "${DOCS_CONF_PY_CNT}")
    file(WRITE "${DOCS_CONF_PY_FILE}" "${DOCS_CONF_PY_CNT}")
    remove_cmake_message_indent()
    message("")
    message("Added 'locale' into 'exclude_patterns' list in 'Documentation/conf.py' file.")
    message("File: ${DOCS_CONF_PY_FILE}")
    message("")
    message("[OLD_EXCLUDE_PATTERNS_LIST_BEGIN]")
    message("${OLD_EXCLUDE_PATTERNS_LIST}")
    message("[OLD_EXCLUDE_PATTERNS_LIST_END]")
    message("[NEW_EXCLUDE_PATTERNS_LIST_BEGIN]")
    message("${NEW_EXCLUDE_PATTERNS_LIST}")
    message("[NEW_EXCLUDE_PATTERNS_LIST_END]")
    message("")
    restore_cmake_message_indent()
else ()
    remove_cmake_message_indent()
    message("")
    message("No need to add 'locale' into 'exclude_patterns' list in 'Documentation/conf.py' file.")
    message("File: ${DOCS_CONF_PY_FILE}")
    message("")
    restore_cmake_message_indent()
endif()


message(STATUS "Removing 'translations' from 'extensions' list in 'Documentation/conf.py' file...")
file(READ "${DOCS_CONF_PY_FILE}" DOCS_CONF_PY_CNT)
set(EXTENSIONS_LIST_REGEX "([^a-zA-Z_]|^)(extensions[ ]*=[ ]*[\[][^\]]*[\]])")
string(REGEX MATCH "${EXTENSIONS_LIST_REGEX}" OLD_EXTENSIONS_LIST "${DOCS_CONF_PY_CNT}")
message(STATUS "OLD_EXTENSIONS_LIST: ${OLD_EXTENSIONS_LIST}")
if (OLD_EXTENSIONS_LIST AND
    OLD_EXTENSIONS_LIST MATCHES "'translations'")
    string(REGEX REPLACE ",[ ]*'translations'" "" NEW_EXTENSIONS_LIST "${OLD_EXTENSIONS_LIST}")
    string(REGEX REPLACE "${EXTENSIONS_LIST_REGEX}" "${NEW_EXTENSIONS_LIST}" DOCS_CONF_PY_CNT "${DOCS_CONF_PY_CNT}")
    file(WRITE "${DOCS_CONF_PY_FILE}" "${DOCS_CONF_PY_CNT}")
    remove_cmake_message_indent()
    message("")
    message("Removed 'translations' from 'extensions' list in 'Documentation/conf.py' file.")
    message("File: ${DOCS_CONF_PY_FILE}")
    message("")
    message("[OLD_EXTENSIONS_LIST_BEGIN]")
    message("${OLD_EXTENSIONS_LIST}")
    message("[OLD_EXTENSIONS_LIST_END]")
    message("[NEW_EXTENSIONS_LIST_BEGIN]")
    message("${NEW_EXTENSIONS_LIST}")
    message("[NEW_EXTENSIONS_LIST_END]")
    message("")
    restore_cmake_message_indent()
else ()
    remove_cmake_message_indent()
    message("")
    message("No need to remove 'translations' from 'extensions' list in 'Documentation/conf.py' file.")
    message("File: ${DOCS_CONF_PY_FILE}")
    message("")
    restore_cmake_message_indent()
endif()


message(STATUS "Removing 'Translations' section in 'Documentation/index.rst' file...")
file(READ "${DOCS_INDEX_RST_FILE}" DOCS_INDEX_RST_CNT)
set(TRANSLATION_SECTION_REGEX "")
set(TRANSLATION_SECTION_REGEX "${TRANSLATION_SECTION_REGEX}Translations[\n][=]+[\n]+")
set(TRANSLATION_SECTION_REGEX "${TRANSLATION_SECTION_REGEX}.. toctree::[\n]+")
set(TRANSLATION_SECTION_REGEX "${TRANSLATION_SECTION_REGEX}[ ]+:maxdepth: 2[\n]+")
set(TRANSLATION_SECTION_REGEX "${TRANSLATION_SECTION_REGEX}[ ]+(Translations <)?translations/index(>)?[\n]")
string(REGEX MATCH "${TRANSLATION_SECTION_REGEX}" OLD_TRANSLATION_SECTION "${DOCS_INDEX_RST_CNT}")
if (OLD_TRANSLATION_SECTION)
    string(REGEX REPLACE "${TRANSLATION_SECTION_REGEX}" "" NEW_TRANSLATION_SECTION "${OLD_TRANSLATION_SECTION}")
    string(REGEX REPLACE "${TRANSLATION_SECTION_REGEX}" "${NEW_TRANSLATION_SECTION}" DOCS_INDEX_RST_CNT "${DOCS_INDEX_RST_CNT}")
    file(WRITE "${DOCS_INDEX_RST_FILE}" "${DOCS_INDEX_RST_CNT}")
    remove_cmake_message_indent()
    message("")
    message("Removed 'Translations' section in 'Documentation/index.rst' file.")
    message("File: ${DOCS_INDEX_RST_FILE}")
    message("")
    message("[OLD_TRANSLATION_SECTION_BEGIN]")
    message("${OLD_TRANSLATION_SECTION}")
    message("[OLD_TRANSLATION_SECTION_END]")
    message("[NEW_TRANSLATION_SECTION_BEGIN]")
    message("${NEW_TRANSLATION_SECTION}")
    message("[NEW_TRANSLATION_SECTION_END]")
    message("")
    restore_cmake_message_indent()
else()
    remove_cmake_message_indent()
    message("")
    message("No need to remove 'Translations' section in 'Documentation/index.rst' file.")
    message("File: ${DOCS_INDEX_RST_FILE}")
    message("")
    restore_cmake_message_indent()
endif()


message(STATUS "Removing directory '${DOCS_TRANSLATION_DIR}/'...")
if (EXISTS "${DOCS_TRANSLATION_DIR}")
    file(REMOVE_RECURSE "${DOCS_TRANSLATION_DIR}")
    remove_cmake_message_indent()
    message("")
    message("Removed directory '${DOCS_TRANSLATION_DIR}/'.")
    message("")
    restore_cmake_message_indent()
else()
    remove_cmake_message_indent()
    message("")
    message("No need to removed directory '${DOCS_TRANSLATION_DIR}/'.")
    message("")
    restore_cmake_message_indent()
endif()


message(STATUS "Adding 'custom' into 'extensions' list in 'conf.py' file...")
set(SPHINX_CONF_PY_FILE "${PROJ_OUT_REPO_DOCS_CONFIG_DIR}/conf.py")
file(READ "${SPHINX_CONF_PY_FILE}" SPHINX_CONF_PY_CNT)
set(EXTENSIONS_LIST_REGEX "([^a-zA-Z_]|^)(extensions[ ]*=[ ]*[\[])([^\]]*[\]])")
string(REGEX MATCH "${EXTENSIONS_LIST_REGEX}" OLD_EXTENSIONS_LIST "${SPHINX_CONF_PY_CNT}")
if (OLD_EXTENSIONS_LIST)
    if (NOT OLD_EXTENSIONS_LIST MATCHES "\"custom\"")
        string(REGEX REPLACE "${EXTENSIONS_LIST_REGEX}" "\\1\\2\"custom\", \\3" NEW_EXTENSIONS_LIST "${OLD_EXTENSIONS_LIST}")
        string(REGEX REPLACE "${EXTENSIONS_LIST_REGEX}" "${NEW_EXTENSIONS_LIST}" SPHINX_CONF_PY_CNT "${SPHINX_CONF_PY_CNT}")
        file(WRITE "${SPHINX_CONF_PY_FILE}" "${SPHINX_CONF_PY_CNT}")
        remove_cmake_message_indent()
        message("")
        message("Added 'custom' into 'extensions' list in 'conf.py' file.")
        message("File: ${SPHINX_CONF_PY_FILE}")
        message("")
        message("[OLD_EXTENSIONS_LIST_BEGIN]")
        message("${OLD_EXTENSIONS_LIST}")
        message("[OLD_EXTENSIONS_LIST_END]")
        message("[NEW_EXTENSIONS_LIST_BEGIN]")
        message("${NEW_EXTENSIONS_LIST}")
        message("[NEW_EXTENSIONS_LIST_END]")
        message("")
        restore_cmake_message_indent()
    else()
        remove_cmake_message_indent()
        message("")
        message("No need to add 'custom' into 'extensions' list in 'conf.py' file.")
        message("File: ${SPHINX_CONF_PY_FILE}")
        message("")
        message("[OLD_EXTENSIONS_LIST_BEGIN]")
        message("${OLD_EXTENSIONS_LIST}")
        message("[OLD_EXTENSIONS_LIST_END]")
        message("")
        restore_cmake_message_indent()
    endif()
else()
    set(EXTENSIONS_LIST "extensions = [\"custom\"]")
    file(APPEND "${SPHINX_CONF_PY_FILE}" "\n${EXTENSIONS_LIST}\n")
    remove_cmake_message_indent()
    message("")
    message("'extensions' list not found. Appending '${EXTENSIONS_LIST}' to 'conf.py' file.")
    message("File: ${SPHINX_CONF_PY_FILE}")
    message("")
    message("[NEWLY_ADDED_CONTENT_BEGIN]")
    message("${EXTENSIONS_LIST}")
    message("[NEWLY_ADDED_CONTENT_END]")
    message("")
    restore_cmake_message_indent()
endif()


message(STATUS "Copying 'custom.py' file to the sphinx extensions directory...")
file(MAKE_DIRECTORY "${PROJ_OUT_REPO_DOCS_EXTNS_DIR}")
file(COPY_FILE
    "${PROJ_CMAKE_CUSTOM_DIR}/custom.py"
    "${PROJ_OUT_REPO_DOCS_EXTNS_DIR}/custom.py")
remove_cmake_message_indent()
message("")
message("From:  ${PROJ_CMAKE_CUSTOM_DIR}/custom.py")
message("To:    ${PROJ_OUT_REPO_DOCS_EXTNS_DIR}/custom.py")
message("")
restore_cmake_message_indent()


message(STATUS "Copying 'layout.html' file to the sphinx templates directory...")
file(MAKE_DIRECTORY "${PROJ_OUT_REPO_DOCS_TMPLS_DIR}")
file(COPY_FILE
    "${PROJ_CMAKE_CUSTOM_DIR}/layout.html"
    "${PROJ_OUT_REPO_DOCS_TMPLS_DIR}/layout.html")
remove_cmake_message_indent()
message("")
message("From: ${PROJ_CMAKE_CUSTOM_DIR}/layout.html")
message("To:   ${PROJ_OUT_REPO_DOCS_TMPLS_DIR}/layout.html")
message("")
restore_cmake_message_indent()


if (NOT UPDATE_POT_REQUIRED)
    message(STATUS "No need to update .pot files.")
    return()
else()
    message(STATUS "Prepare to update .pot files.")
endif()


message(STATUS "Removing directory '${PROJ_OUT_REPO_DOCS_LOCALE_DIR}/'...")
if (EXISTS "${PROJ_OUT_REPO_DOCS_LOCALE_DIR}")
    file(REMOVE_RECURSE "${PROJ_OUT_REPO_DOCS_LOCALE_DIR}")
    remove_cmake_message_indent()
    message("")
    message("Directory '${PROJ_OUT_REPO_DOCS_LOCALE_DIR}/' exists.")
    message("Removed '${PROJ_OUT_REPO_DOCS_LOCALE_DIR}/'.")
    message("")
    restore_cmake_message_indent()
else()
    remove_cmake_message_indent()
    message("")
    message("Directory '${PROJ_OUT_REPO_DOCS_LOCALE_DIR}/' does NOT exist.")
    message("No need to remove '${PROJ_OUT_REPO_DOCS_LOCALE_DIR}/'.")
    message("")
    restore_cmake_message_indent()
endif()


message(STATUS "Running 'make gettextdocs' command to generate .pot files...")
file(MAKE_DIRECTORY "${PROJ_OUT_REPO_DOCS_LOCALE_DIR}/pot/LC_MESSAGES")
if (CMAKE_HOST_LINUX)
    set(ENV_PATH                "${PROJ_CONDA_DIR}/bin:$ENV{PATH}")
    set(ENV_LD_LIBRARY_PATH     "${PROJ_CONDA_DIR}/lib:$ENV{ENV_LD_LIBRARY_PATH}")
    set(ENV_PYTHONPATH          "${PROJ_OUT_REPO_DOCS_EXTNS_DIR}")
    set(ENV_VARS_OF_SYSTEM      PATH=${ENV_PATH}
                                LD_LIBRARY_PATH=${ENV_LD_LIBRARY_PATH}
                                PYTHONPATH=${ENV_PYTHONPATH})
else()
    message(FATAL_ERROR "Invalid OS platform. (${CMAKE_HOST_SYSTEM_NAME})")
endif()
set(WARNING_FILE_PATH   "${PROJ_BINARY_DIR}/log-gettext-${VERSION}.txt")
set(BUILDDIR            "${PROJ_OUT_REPO_DOCS_LOCALE_DIR}/pot/LC_MESSAGES")
set(SPHINXBUILD         "${Sphinx_BUILD_EXECUTABLE}")
set(SPHINXOPTS          "")
set(SPHINXOPTS          "${SPHINXOPTS} -D version=${VERSION}")
set(SPHINXOPTS          "${SPHINXOPTS} -D templates_path=${TMPLS_TO_SOURCE_DIR}")
set(SPHINXOPTS          "${SPHINXOPTS} -D gettext_compact=${SPHINX_GETTEXT_COMPACT}")
set(SPHINXOPTS          "${SPHINXOPTS} -D gettext_additional_targets=${SPHINX_GETTEXT_TARGETS}")
set(SPHINXOPTS          "${SPHINXOPTS} -j ${SPHINX_JOB_NUMBER}")
set(SPHINXOPTS          "${SPHINXOPTS} -w ${WARNING_FILE_PATH}")
set(SPHINXOPTS          "${SPHINXOPTS} ${SPHINX_VERBOSE_ARGS}")
set(KERNELVERSION       "${VERSION}")
remove_cmake_message_indent()
message("")
execute_process(
    COMMAND ${CMAKE_COMMAND} -E env
            ${ENV_VARS_OF_SYSTEM}
            ${CMAKE_MAKE_PROGRAM} gettextdocs V=12
            BUILDDIR=${BUILDDIR}
            SPHINXBUILD=${SPHINXBUILD}
            SPHINXOPTS=${SPHINXOPTS}
            KERNELVERSION=${KERNELVERSION}
    WORKING_DIRECTORY ${PROJ_OUT_REPO_DIR}
    ECHO_OUTPUT_VARIABLE
    RESULT_VARIABLE RES_VAR
    OUTPUT_VARIABLE OUT_VAR OUTPUT_STRIP_TRAILING_WHITESPACE
    ERROR_VARIABLE  ERR_VAR ERROR_STRIP_TRAILING_WHITESPACE)
if (RES_VAR EQUAL 0)
    if (ERR_VAR)
        string(APPEND WARNING_REASON
        "The command succeeded with warnings.\n\n"
        "    result:\n\n${RES_VAR}\n\n"
        "    stderr:\n\n${ERR_VAR}")
        message("${WARNING_REASON}")
    endif()
else()
    string(APPEND FAILURE_REASON
    "The command failed with fatal errors.\n"
    "    result:\n${RES_VAR}\n"
    "    stderr:\n${ERR_VAR}")
    message(FATAL_ERROR "${FAILURE_REASON}")
endif()
message("")
restore_cmake_message_indent()


message(STATUS "Running 'msgcat' command to update 'sphinx.pot' file...")
execute_process(
    COMMAND ${Python_EXECUTABLE} -c "import sphinx; print(sphinx.__file__);"
    RESULT_VARIABLE RES_VAR
    OUTPUT_VARIABLE OUT_VAR OUTPUT_STRIP_TRAILING_WHITESPACE
    ERROR_VARIABLE  ERR_VAR ERROR_STRIP_TRAILING_WHITESPACE)
if (RES_VAR EQUAL 0)
    get_filename_component(SPHINX_LIB_DIR "${OUT_VAR}" DIRECTORY)
else()
    string(APPEND FAILURE_REASON
    "The command failed with fatal errors.\n"
    "    result:\n${RES_VAR}\n"
    "    stdout:\n${OUT_VAR}\n"
    "    stderr:\n${ERR_VAR}")
    message(FATAL_ERROR "${FAILURE_REASON}")
endif()
set(DEFAULT_SPHINX_POT_FILE "${SPHINX_LIB_DIR}/locale/sphinx.pot")
set(PACKAGE_SPHINX_POT_FILE "${PROJ_OUT_REPO_DOCS_LOCALE_DIR}/pot/LC_MESSAGES/sphinx.pot")
remove_cmake_message_indent()
message("")
message("From: ${DEFAULT_SPHINX_POT_FILE}")
message("To:   ${PACKAGE_SPHINX_POT_FILE}")
message("")
update_sphinx_pot_from_def_to_pkg(
    IN_DEF_FILE     "${DEFAULT_SPHINX_POT_FILE}"
    IN_PKG_FILE     "${PACKAGE_SPHINX_POT_FILE}"
    IN_WRAP_WIDTH   "${GETTEXT_WRAP_WIDTH}")
message("")
restore_cmake_message_indent()


message(STATUS "Running 'msgmerge/msgcat' command to update .pot files...")
set(SRC_POT_DIR "${PROJ_OUT_REPO_DOCS_LOCALE_DIR}/pot")
set(DST_POT_DIR "${PROJ_L10N_VERSION_LOCALE_DIR}/pot")
remove_cmake_message_indent()
message("")
message("From: ${SRC_POT_DIR}/")
message("To:   ${DST_POT_DIR}/")
message("")
update_pot_from_src_to_dst(
    IN_SRC_DIR      "${SRC_POT_DIR}"
    IN_DST_DIR      "${DST_POT_DIR}"
    IN_WRAP_WIDTH   "${GETTEXT_WRAP_WIDTH}")
message("")
restore_cmake_message_indent()


set_json_value_by_dot_notation(
    IN_JSON_OBJECT      "${REFERENCES_JSON_CNT}"
    IN_DOT_NOTATION     ".pot"
    IN_JSON_VALUE       "${LATEST_POT_OBJECT}"
    OUT_JSON_OBJECT     REFERENCES_JSON_CNT)


file(WRITE "${REFERENCES_JSON_PATH}" "${REFERENCES_JSON_CNT}")
