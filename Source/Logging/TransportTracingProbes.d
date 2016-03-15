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
