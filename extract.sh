#! /bin/bash

# Prepare Directory
OUTPUT_DIR=output
OUTPUT_TMPDIR=.O
INFRA_DIR=${OUTPUT_DIR}/eng/infra
WRAPPERS_DIR=${OUTPUT_DIR}/eng/wrappers
EXAMPLES_DIR=${OUTPUT_DIR}/eng/examples

gen_eng_dir() {
    rm -rf ${OUTPUT_DIR}/eng
    mkdir -p ${INFRA_DIR}
    mkdir -p ${EXAMPLES_DIR}
    mkdir -p ${WRAPPERS_DIR}
    echo "" > ${WRAPPERS_DIR}/wrapper.c
}

# Prepare Config Macro In make.settings
MACRO_LIST=$(sed -n '/#/!{/=y/p}' make.settings | sed -n 's/=y//gp' | sed -n 's/FEATURE_//gp')

# Function
gen_infra_default () {
    CONFIG_H=$(echo "${1}" | sed -n 's/^/#define /p')
    echo "#ifndef _INFRA_CONFIG_H_" > ${INFRA_DIR}/infra_config.h
    echo -e "#define _INFRA_CONFIG_H_\n" >> ${INFRA_DIR}/infra_config.h
    echo "${CONFIG_H}" >> ${INFRA_DIR}/infra_config.h
    echo -e "\n#endif" >> ${INFRA_DIR}/infra_config.h
}

gen_infra_module() {
    M_INFRA=$(echo "${1}" | grep 'INFRA')
    echo "extract infra module..."
    echo -e "${M_INFRA}\n"
    find . -path ./${OUTPUT_DIR} -prune -type f -o -name "infra_types.h" | xargs -i cp -f {} ${INFRA_DIR}
    find . -path ./${OUTPUT_DIR} -prune -type f -o -name "infra_defs.[ch]" | xargs -i cp -f {} ${INFRA_DIR}
    find . -path ./${OUTPUT_DIR} -prune -type f -o -name "infra_compat.h" | xargs -i cp -f {} ${INFRA_DIR}

    echo "${M_INFRA}" | while read line;
    do
        find . \( -path ./${OUTPUT_DIR} -o -path ./${OUTPUT_TMPDIR} \) -prune -type f -o -iname "${line}.[ch]" | xargs -i cp -f {} ${INFRA_DIR}
    done
}

gen_wrapper_c() {
    M_MQTT_DEFAULT_IMPL=$(echo "${1}" | grep -w 'MQTT_DEFAULT_IMPL')

    WRAPPER_FUNCS=$(find ./${OUTPUT_DIR}/eng -name *wrapper.h | xargs -i grep -ro "HAL_.*(" {} | sed 's/(//g' | sort -u)"\n"
    WRAPPER_FUNCS+=$(find ./${OUTPUT_DIR}/eng -name *wrapper.h | xargs -i grep -ro "wrapper_.*(" {} | sed 's/(//g' | sort -u)

    [[ ${M_MQTT_DEFAULT_IMPL} ]] && WRAPPER_FUNCS=$(echo -e "${WRAPPER_FUNCS}" | sed -n '/wrapper_mqtt/!{p}')

    echo -e "#include \"infra_types.h\"" >> ${WRAPPERS_DIR}/wrapper.c
    echo -e "#include \"infra_defs.h\"\n" >> ${WRAPPERS_DIR}/wrapper.c

    # echo -e "${WRAPPER_FUNCS}" |awk '{ printf("%03d %s\n", NR, $0); }'

    echo -e "${WRAPPER_FUNCS}" | while read func
    do
        [[ ! ${func} ]] && return

        FUNC_DEC=$(find ./${OUTPUT_DIR}/eng -name *wrapper.h | xargs -i cat {} 2>/dev/null | sed -n '/.*'$func'(.*/{/.*);/ba;{:c;N;/.*);/!bc};:a;p;q}')
        DATA_TYPE=$(echo "${FUNC_DEC}" | head -1 | awk -F'wrapper|HAL' '{print $1}' | sed s/[[:space:]]//g)

        if [ "${DATA_TYPE}" == "void" ];then
            echo "${FUNC_DEC}" | sed -n '/;/{s/;/\n{\n\treturn;\n}\n\n/g};p' >> ${WRAPPERS_DIR}/wrapper.c
        else
            echo "${FUNC_DEC}" | sed -n '/;/{s/;/\n{\n\treturn ('${DATA_TYPE}')1;\n}\n\n/g};p' >> ${WRAPPERS_DIR}/wrapper.c
        fi
    done

}

gen_dev_sign_module() {
    M_DEV_SIGN=$(echo "${1}" | grep -w 'DEV_SIGN')

    [[ ! ${M_DEV_SIGN} ]] && return

    DEV_SIGN_DIR=${OUTPUT_DIR}/eng/dev_sign
    mkdir -p ${DEV_SIGN_DIR}
    echo "extract dev_sign module..."
    echo -e "${M_DEV_SIGN}\n"

    SRC_DEV_SIGN=$([[ ${M_DEV_SIGN} ]] && find ./src \( -path ./${OUTPUT_DIR} -o -path ./${OUTPUT_TMPDIR} \) -prune -type f -o -iname ${M_DEV_SIGN} -type d)
    if [ ${SRC_DEV_SIGN} ];then
        find ${SRC_DEV_SIGN} -maxdepth 1 -name *.[ch] | grep -v example | xargs -i cp -f {} ${DEV_SIGN_DIR}
        find ${SRC_DEV_SIGN} -maxdepth 1 -name *example*.c | xargs -i cp -f {} ${EXAMPLES_DIR}
    fi
}

gen_mqtt_module() {
    M_MQTT_COMM_ENABLED=$(echo "${1}" | grep -w 'MQTT_COMM_ENABLED')
    M_MQTT_DEFAULT_IMPL=$(echo "${1}" | grep -w 'MQTT_DEFAULT_IMPL')
    M_MAL_ENABLED=$(echo "${1}" | grep -w 'MAL_ENABLED')
    M_MAL_ICA_ENABLED=$(echo "${1}" | grep -w 'MAL_ICA_ENABLED')

    [[ ! ${M_MQTT_COMM_ENABLED} ]] && return

    MQTT_DIR=${OUTPUT_DIR}/eng/mqtt
    mkdir -p ${MQTT_DIR}
    echo "extract mqtt module..."
    echo -e "$(echo "${1}" | grep -E 'MQTT|MAL')\n"

    SRC_MQTT_SIGN=$([[ ${M_MQTT_COMM_ENABLED} ]] && find ./src \( -path ./${OUTPUT_DIR} -o -path ./${OUTPUT_TMPDIR} \) -prune -type f -o -iname "mqtt" -type d)
    if [ ${SRC_MQTT_SIGN} ];then
        find ${SRC_MQTT_SIGN} -maxdepth 1 -name *.[ch] | grep -v example | xargs -i cp -f {} ${MQTT_DIR}
        [[ ${M_MQTT_DEFAULT_IMPL} ]] && find ${SRC_MQTT_SIGN} -name mqtt_impl -type d | xargs -i cp -rf {} ${MQTT_DIR}
        [[ ${M_MQTT_DEFAULT_IMPL} ]] && find ${SRC_MQTT_SIGN} -maxdepth 1 -name *example.c | xargs -i cp -f {} ${EXAMPLES_DIR}
    fi

    SRC_MAL_WRAPPER=$([[ ${M_MAL_ENABLED} ]] && find ./wrappers \( -path ./${OUTPUT_DIR} -o -path ./${OUTPUT_TMPDIR} \) -prune -type f -o -iname "mal" -type d)
    if [ ${SRC_MAL_WRAPPER} ];then
        mkdir -p ${WRAPPERS_DIR}/mqtt/mal
        find ${SRC_MAL_WRAPPER} -maxdepth 1 -name *.[ch] | grep -v example | xargs -i cp -f {} ${WRAPPERS_DIR}/mqtt/mal
        [[ ${M_MAL_ICA_ENABLED} ]] && find ${SRC_MAL_WRAPPER} -name ica -type d | xargs -i cp -rf {} ${WRAPPERS_DIR}/mqtt/mal
    fi
}

gen_sal_module() {
    M_SAL_ENABLED=$(echo "${1}" | grep -w 'SAL_ENABLED')
    M_SAL_HAL_IMPL_ENABLED=$(echo "${1}" | grep -w 'SAL_HAL_IMPL_ENABLED')

    [[ ! ${M_SAL_ENABLED} ]] && return

    echo "extract sal module..."
    echo -e "$(echo "${1}" | grep -E 'SAL')\n"

    SRC_SAL=$([[ ${M_SAL_ENABLED} ]] && find ./wrappers \( -path ./${OUTPUT_DIR} -o -path ./${OUTPUT_TMPDIR} \) -prune -type f -o -iname "sal" -type d)
    if [ ${SRC_SAL} ];then
        mkdir -p ${WRAPPERS_DIR}/sal/
        find ${SRC_SAL} -maxdepth 1 -name *.[ch] | grep -v example | xargs -i cp -f {} ${WRAPPERS_DIR}/sal/
        find ${SRC_SAL} -name src -type d | xargs -i cp -rf {} ${WRAPPERS_DIR}/sal
        find ${SRC_SAL} -name include -type d | xargs -i cp -rf {} ${WRAPPERS_DIR}/sal

        SRC_SAL_AT=$([[ ${M_SAL_HAL_IMPL_ENABLED} ]] && find ./wrappers \( -path ./${OUTPUT_DIR} -o -path ./${OUTPUT_TMPDIR} \) -prune -type f -o -iname "at" -type d)
        [[ ${M_SAL_HAL_IMPL_ENABLED} ]] && find ${SRC_SAL} -name hal-impl -type d | xargs -i cp -rf {} ${WRAPPERS_DIR}/sal
        [[ ${M_SAL_HAL_IMPL_ENABLED} ]] && find ${SRC_SAL_AT} -name at -type d | xargs -i cp -rf {} ${WRAPPERS_DIR}
    fi
    # mkdir -p ${WRAPPERS_DIR}/sal
}

# Generate Directory
gen_eng_dir

# Generate infra_config.h
gen_infra_default "${MACRO_LIST}"

# Generate Module Code
gen_infra_module "${MACRO_LIST}"
gen_dev_sign_module "${MACRO_LIST}"
gen_mqtt_module "${MACRO_LIST}"
gen_sal_module "${MACRO_LIST}"
gen_wrapper_c "${MACRO_LIST}"