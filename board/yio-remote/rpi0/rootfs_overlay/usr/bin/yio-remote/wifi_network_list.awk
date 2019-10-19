# BusyBox compatible awk parsing of 'iw wlan0 scan' output
# Inspired by: https://gist.github.com/elecnix/182fa522da5dc7389975
# Returns rows of <signal_strength>,<SSID> values
#BEGIN {
#    # table header
#    printf("%s,%s\n","signal","SSID");
#}
NF > 0{
    if ($1 == "BSS" && $2 ~ /^[a-z0-9:]{17}\(?/) {
        if( e["MAC"] ){
            # new block: print result from last block
            printf("%s,%s\n",e["sig"],e["SSID"]);
        }
        e["MAC"] = $2;
    }
    if ($1 == "SSID:") {
        # $2 might not contain the full SSID name if it has an awk separator char in it's name!
        e["SSID"] = substr($0, index($0,$2));
    }
    if ($1 == "freq:") {
        e["freq"] = $NF;
    }
    if ($1 == "signal:") {
        e["sig"] = $2;
        e["sig%"] = (60 - ((-$2) - 40)) * 100 / 60;
    }
}
END {
    # final block
    printf("%s,%s\n",e["sig"],e["SSID"]);
}