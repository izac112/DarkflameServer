#ifndef __EMATCHUPDATE__H__
#define __EMATCHUPDATE__H__

#include <cstdint>

enum class eMatchUpdate : int32_t {
	PLAYER_ADDED = 0,
	PLAYER_REMOVED,
	PHASE_CREATED,
	PHASE_WAIT_READY,
	PHASE_WAIT_START,
	PLAYER_READY,
	PLAYER_NOT_READY,
	PLAYER_UPDATE
};

#endif  //!__EMATCHUPDATE__H__
