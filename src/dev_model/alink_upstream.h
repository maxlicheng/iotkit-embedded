/*
 * Copyright (C) 2015-2018 Alibaba Group Holding Limited
 */

#ifndef __ALINK_UPSTREAM__
#define __ALINK_UPSTREAM__

#include "iotx_alink_internal.h"

/* thing model upstream */
int alink_upstream_thing_property_post_req(const char *pk, const char *dn, const char *user_data, uint32_t data_len);
int alink_upstream_thing_property_set_rsp(const char *pk, const char *dn, uint32_t code);
int alink_upstream_thing_property_get_rsp(const char *pk, const char *dn, uint32_t code, const char *user_data, uint32_t data_len);

int alink_upstream_thing_event_post_req(const char *pk, const char *dn, const char *event_id, uint8_t id_len, const char *user_data, uint32_t data_len);
int alink_upstream_thing_raw_post_req(const char *pk, const char *dn, const uint8_t *user_data, uint32_t data_len);

/* subdev manager upstream */



/* thing devinfo stream */
int alink_upstream_thing_deviceinfo_post_req(const char *pk, const char *dn, const char *user_data, uint32_t data_len);
int alink_upstream_thing_deviceinfo_get_req(const char *pk, const char *dn);
int alink_upstream_thing_deviceinfo_delete_req(const char *pk, const char *dn, const char *user_data, uint32_t data_len);


#endif /* #ifndef __ALINK_UPSTREAM__ */