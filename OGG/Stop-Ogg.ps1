Stop-OggProcess -ComputerName $src_server -OggHome $src_ogg_home -ProcessName $extract_name
Stop-OggProcess -ComputerName $src_server -OggHome $src_ogg_home -ProcessName $pump_name
Stop-OggProcess -ComputerName $tgt_server -OggHome $tgt_ogg_home -ProcessName $replicat_name
