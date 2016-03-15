/* 
*  Wire
*  Copyright (C) 2016 Wire Swiss GmbH
*  
*  This program is free software: you can redistribute it and/or modify
*  it under the terms of the GNU General Public License as published by
*  the Free Software Foundation, either version 3 of the License, or
*  (at your option) any later version.
*  
*  This program is distributed in the hope that it will be useful,
*  but WITHOUT ANY WARRANTY; without even the implied warranty of
*  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
*  GNU General Public License for more details.
*  
*  You should have received a copy of the GNU General Public License
*  along with this program. If not, see <http://www.gnu.org/licenses/>.
*/ 




/* Operation Loop / Sync Strategy */
provider syncengine_sync {

probe operation_loop_enqueue(int, int, intptr_t);
probe operation_loop_push_channel_data(int, int);
probe strategy_go_to_state(char *);
probe strategy_leave_state(char *);
probe strategy_update_event(int, int);
probe strategy_update_event_string(int, char *);

};



/* User Interface related */

provider syncengine_ui {

probe notification(int, intptr_t, char *, char *, int, int, int, int);
probe message_window_change(intptr_t, intptr_t, int, int, intptr_t, intptr_t *, intptr_t, intptr_t *);
probe message_window_notification(intptr_t, intptr_t, int);

};



/* Transcoders */

provider syncengine_transcoder {

probe call_state_req_update_is_joined(int, char *, int);

};



/* ZMTransportSession and related classes. */

provider syncengine_transport {

probe access_token_request(int, int, intptr_t);

/* probes related to push channel, but inside ZMTransportSession: */
probe push_channel_creation(int, intptr_t, int);
probe push_channel_creation_backoff(int, int);
probe push_channel_creation_event(int, intptr_t, int);

/* probes inside ZMPushChannel: */
probe push_channel_ping_start_stop(intptr_t, int, int);
probe push_channel_ping_fired(intptr_t);
probe push_channel_event(intptr_t, intptr_t, int);
probe web_socket_event(intptr_t, intptr_t, int, int);
probe network_socket_event(intptr_t, intptr_t, int, int);

probe session_task_transcoder(intptr_t, int);
probe session_task(int, intptr_t, char *, char *, int, int, char *, char *);
probe session_task_error(int, intptr_t, char *, intptr_t);
probe session_reachability(int, int);

probe request_scheduler(int, intptr_t, intptr_t);

};



/* Calling */

provider syncengine_calling {

probe session(char *);
probe flow_manager_category(char *, int);
probe flow_acquire(char *);
probe flow_release(char *);
probe device_is_active(char *, int);
probe push_event_participant(char *, char *, int, int);
probe push_event_self(char *, int, int);
probe downstream_event_participant(char *, char *, int, int);
probe downstream_event_self(char *, int, int);
probe upstream_event_participant(char *, char *, int, int);
probe upstream_event_self(char *, int, int);
probe voice_gain(char *, char *, double);

};



/* Core Data */

provider syncengine_core_data {

probe enqueue_save(int, int, int);
probe perform_group_enter(int); /* context */
probe perform_group_exit();
probe manual_refresh(char *, int); /* object-id, context */

};

/* Authentication */
provider syncengine_auth {
  
probe delete_cookie_data(int);
probe add_cookie_data(int);
probe update_cookie_data(int);
probe detected_locked_keychain();
probe user_session_started(bool, bool);
probe user_session_login(char *, int);
probe credentials_deleted();
probe credentials_set();
probe login_state_fire_login_timer();
probe login_state_enter(int);
probe login_state_next_request(int, bool);
probe request_will_contain_token(char *);
probe request_will_contain_cookie(char *);
probe access_token_response(int, bool);

};


/* Imags */

provider syncengine_image {
    
    probe downsample_original(unsigned long, char *);
    probe downsample_scale(unsigned long, char *);
    probe downsample_recompress(unsigned long, char *);
};
