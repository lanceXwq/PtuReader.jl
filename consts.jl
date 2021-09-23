const ty_empty8 = 0xFFFF0008
const ty_bool8 = 0x00000008
const ty_int8 = 0x10000008
const ty_bitset64 = 0x11000008
const ty_color8 = 0x12000008
const ty_float8 = 0x20000008
const ty_tdatetime = 0x21000008
const ty_float8array = 0x2001FFFF
const ty_ansistring = 0x4001FFFF
const ty_widestring = 0x4002FFFF
const ty_binaryblob = 0xFFFFFFFF

const rt_picoharp_t3 = 0x00010303 # (SubID = $00 ,RecFmt: $01) (V1), T-Mode: $03 (T3), HW: $03 (PicoHarp)
const rt_picoharp_t2 = 0x00010203 # (SubID = $00 ,RecFmt: $01) (V1), T-Mode: $02 (T2), HW: $03 (PicoHarp)
const rt_hydraharp_t3 = 0x00010304 # (SubID = $00 ,RecFmt: $01) (V1), T-Mode: $03 (T3), HW: $04 (HydraHarp)
const rt_hydraharp_t2 = 0x00010204 # (SubID = $00 ,RecFmt: $01) (V1), T-Mode: $02 (T2), HW: $04 (HydraHarp)
const rt_hydraharp2_t3 = 0x01010304  # (SubID = $01 ,RecFmt: $01) (V2), T-Mode: $03 (T3), HW: $04 (HydraHarp)
const rt_hydraharp2_t2 = 0x01010204  # (SubID = $01 ,RecFmt: $01) (V2), T-Mode: $02 (T2), HW: $04 (HydraHarp)
const rt_timeharp_260n_t3 = 0x00010305  # (SubID = $00 ,RecFmt: $01) (V1), T-Mode: $03 (T3), HW: $05 (TimeHarp260N)
const rt_timeharp_260n_t2 = 0x00010205  # (SubID = $00 ,RecFmt: $01) (V1), T-Mode: $02 (T2), HW: $05 (TimeHarp260N)
const rt_timeharp_260p_t3 = 0x00010306  # (SubID = $00 ,RecFmt: $01) (V1), T-Mode: $03 (T3), HW: $06 (TimeHarp260P)
const rt_timeharp_260p_t2 = 0x00010206  # (SubID = $00 ,RecFmt: $01) (V1), T-Mode: $02 (T2), HW: $06 (TimeHarp260P)
const rt_multiharp_t3 = 0x00010307 # (SubID = $00 ,RecFmt: $01) (V1), T-Mode: $03 (T3), HW: $07 (MultiHarp)
const rt_multiharp_t2 = 0x00010207 # (SubID = $00 ,RecFmt: $01) (V1), T-Mode: $02 (T2), HW: $07 (MultiHarp)