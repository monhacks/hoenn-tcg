AIActionTable_LegendarySlaking:
	dw .do_turn ; unused
	dw .do_turn
	dw .start_duel
	dw .forced_switch
	dw .ko_switch
	dw .take_prize

.do_turn
	call AIDoTurn_LegendarySlaking
	ret

.start_duel
	call InitAIDuelVars
	call .store_list_pointers
	call SetUpBossStartingHandAndDeck
	call TrySetUpBossStartingPlayArea
	ret nc
	call AIPlayInitialBasicCards
	ret

.forced_switch
	call AIDecideBenchPokemonToSwitchTo
	ret

.ko_switch
	call AIDecideBenchPokemonToSwitchTo
	ret

.take_prize
	call AIPickPrizeCards
	ret

.list_arena
	db CRAWDAUNT
	db AGGRON
	db BAGON
	db SLAKOTH
	db MAGIKARP
	db $00

.list_bench
	db BAGON
	db MAGIKARP
	db SLAKOTH
	db AGGRON
	db CRAWDAUNT
	db $00

.list_retreat
	ai_retreat BAGON, -1
	ai_retreat MAGIKARP,   -5
	db $00

.list_energy
	ai_energy BAGON,     3, +1
	ai_energy SHELGON,     4, +1
	ai_energy SALAMENCE,      5, +0
	ai_energy MAGIKARP,       3, +1
	ai_energy GYARADOS,       4, -1
	ai_energy SLAKOTH,        2, +0
	ai_energy VIGOROTH,      4, +0
	ai_energy SLAKING, 3, -1
	ai_energy CRAWDAUNT,     2, -2
	ai_energy AGGRON,         3, +0
	db $00

.list_prize
	db GAMBLER
	db SLAKING
	db CRAWDAUNT
	db $00

.store_list_pointers
	store_list_pointer wAICardListAvoidPrize, .list_prize
	store_list_pointer wAICardListArenaPriority, .list_arena
	store_list_pointer wAICardListBenchPriority, .list_bench
	store_list_pointer wAICardListPlayFromHandPriority, .list_bench
	store_list_pointer wAICardListRetreatBonus, .list_retreat
	store_list_pointer wAICardListEnergyBonus, .list_energy
	ret

AIDoTurn_LegendarySlaking:
; initialize variables
	call InitAITurnVars
	ld a, AI_TRAINER_CARD_PHASE_01
	call AIProcessHandTrainerCards
	call HandleAIAntiMewtwoDeckStrategy
	jp nc, .try_attack
; process Trainer cards
	ld a, AI_TRAINER_CARD_PHASE_02
	call AIProcessHandTrainerCards
; play Pokemon from hand
	call AIDecidePlayPokemonCard
	ret c ; return if turn ended
	ld a, AI_TRAINER_CARD_PHASE_07
	call AIProcessHandTrainerCards
	call AIProcessRetreat
	ld a, AI_TRAINER_CARD_PHASE_10
	call AIProcessHandTrainerCards
	ld a, AI_TRAINER_CARD_PHASE_11
	call AIProcessHandTrainerCards
; play Energy card if possible
	ld a, [wAlreadyDidUniqueAction]
	and PLAYED_ENERGY_THIS_TURN
	jr nz, .skip_energy_attach_1

; if Arena card is Crawdaunt and doesn't
; have Energy cards attached, try attaching from hand.
; otherwise run normal AI energy attach routine.
	ld a, DUELVARS_ARENA_CARD
	call GetTurnDuelistVariable
	call GetCardIDFromDeckIndex
	ld a, CRAWDAUNT
	cp e
	jr nz, .attach_normally
	call CreateEnergyCardListFromHand
	jr c, .skip_energy_attach_1
	ld e, PLAY_AREA_ARENA
	call CountNumberOfEnergyCardsAttached
	or a
	jr nz, .attach_normally
	xor a
	ldh [hTempPlayAreaLocation_ff9d], a
	call AITryToPlayEnergyCard
	jr c, .skip_energy_attach_1
.attach_normally
	call AIProcessAndTryToPlayEnergy

.skip_energy_attach_1
; play Pokemon from hand again
	call AIDecidePlayPokemonCard
	ld a, AI_TRAINER_CARD_PHASE_15
	call AIProcessHandTrainerCards
; if used Professor Oak, process new hand
; if not, then proceed to attack.
	ld a, [wPreviousAIFlags]
	and AI_FLAG_USED_PROFESSOR_BIRCH
	jr z, .try_attack
	ld a, AI_TRAINER_CARD_PHASE_01
	call AIProcessHandTrainerCards
	ld a, AI_TRAINER_CARD_PHASE_02
	call AIProcessHandTrainerCards
	call AIDecidePlayPokemonCard
	ret c ; return if turn ended
	ld a, AI_TRAINER_CARD_PHASE_07
	call AIProcessHandTrainerCards
	call AIProcessRetreat
	ld a, AI_TRAINER_CARD_PHASE_10
	call AIProcessHandTrainerCards
	ld a, AI_TRAINER_CARD_PHASE_11
	call AIProcessHandTrainerCards
	ld a, [wAlreadyDidUniqueAction]
	and PLAYED_ENERGY_THIS_TURN
	jr nz, .skip_energy_attach_2
	call AIProcessAndTryToPlayEnergy
.skip_energy_attach_2
	call AIDecidePlayPokemonCard
.try_attack
; attack if possible, if not,
; finish turn without attacking.
	call AIProcessAndTryToUseAttack
	ret c ; return if turn ended
	ld a, OPPACTION_FINISH_NO_ATTACK
	bank1call AIMakeDecision
	ret
