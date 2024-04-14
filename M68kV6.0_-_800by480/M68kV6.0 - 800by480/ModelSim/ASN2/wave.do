onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate /DRAM_Controller_TB/Clock
add wave -noupdate /DRAM_Controller_TB/Reset_L
add wave -noupdate /DRAM_Controller_TB/Address
add wave -noupdate /DRAM_Controller_TB/DataIn
add wave -noupdate /DRAM_Controller_TB/UDS_L
add wave -noupdate /DRAM_Controller_TB/LDS_L
add wave -noupdate /DRAM_Controller_TB/DramSelect_L
add wave -noupdate /DRAM_Controller_TB/WE_L
add wave -noupdate /DRAM_Controller_TB/AS_L
add wave -noupdate /DRAM_Controller_TB/DataOut
add wave -noupdate /DRAM_Controller_TB/SDram_CKE_H
add wave -noupdate /DRAM_Controller_TB/SDram_CS_L
add wave -noupdate /DRAM_Controller_TB/SDram_RAS_L
add wave -noupdate /DRAM_Controller_TB/SDram_CAS_L
add wave -noupdate /DRAM_Controller_TB/SDram_WE_L
add wave -noupdate /DRAM_Controller_TB/SDram_Addr
add wave -noupdate /DRAM_Controller_TB/SDram_BA
add wave -noupdate /DRAM_Controller_TB/Dtack_L
add wave -noupdate /DRAM_Controller_TB/ResetOut_L
add wave -noupdate /DRAM_Controller_TB/DramState
add wave -noupdate /DRAM_Controller_TB/DUT/TimerLoad_H
add wave -noupdate /DRAM_Controller_TB/DUT/TimerDone_H
add wave -noupdate /DRAM_Controller_TB/DUT/TimerValue
add wave -noupdate /DRAM_Controller_TB/DUT/Command
add wave -noupdate -radix hexadecimal /DRAM_Controller_TB/DUT/CurrentState
add wave -noupdate -radix hexadecimal /DRAM_Controller_TB/DUT/NextState
add wave -noupdate -radix hexadecimal /DRAM_Controller_TB/DUT/AutoRefreshCount
add wave -noupdate -radix hexadecimal /DRAM_Controller_TB/DUT/AutoRefreshNOPCount
add wave -noupdate -radix hexadecimal /DRAM_Controller_TB/DUT/LoadModeRegisterNOPCount
add wave -noupdate /DRAM_Controller_TB/Clock
add wave -noupdate -radix unsigned /DRAM_Controller_TB/DUT/RefreshTimerValue
add wave -noupdate /DRAM_Controller_TB/DUT/RefreshTimerLoad_H
add wave -noupdate /DRAM_Controller_TB/DUT/RefreshTimerDone_H
add wave -noupdate /DRAM_Controller_TB/DUT/RefreshTimerNOPCount
add wave -noupdate -radix unsigned /DRAM_Controller_TB/DUT/RefreshTimer
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {90581 ns} 0}
quietly wave cursor active 1
configure wave -namecolwidth 150
configure wave -valuecolwidth 100
configure wave -justifyvalue left
configure wave -signalnamewidth 1
configure wave -snapdistance 10
configure wave -datasetprefix 0
configure wave -rowmargin 4
configure wave -childrowmargin 2
configure wave -gridoffset 0
configure wave -gridperiod 1
configure wave -griddelta 40
configure wave -timeline 0
configure wave -timelineunits ns
update
WaveRestoreZoom {98008 ns} {98270 ns}
