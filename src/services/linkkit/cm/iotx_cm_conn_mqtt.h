
#ifndef SRC_CLOUD_CONNECTION_MQTT_H_
#define SRC_CLOUD_CONNECTION_MQTT_H_

#include "iotx_cm_connection.h"

void *iotx_cm_conn_mqtt_init(void *handle, void *init_param);

int iotx_cm_conn_mqtt_subscribe(void *handle, void *_register_param, int count);

int iotx_cm_conn_mqtt_unsubscribe(void *handle, const char *topic_filter);

int iotx_cm_conn_mqtt_publish(void *handle, void *_context, iotx_connection_msg_t *message);

int iotx_cm_conn_mqtt_deinit(void *handle);

int iotx_cm_conn_mqtt_yield(void *handle, int timeout_ms);

#endif /* SRC_CLOUD_CONNECTION_MQTT_H_ */