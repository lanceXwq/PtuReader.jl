# Print Photon
# timetag: Raw timetag from record * globalresolution = Real Time arrival of Photon
# dtime: Arrival time of Photon after last Sync event (T3 only) dtime * resolution = Real time arrival of Photon after last Sync event
# channel: channel the Photon arrived (0 = Sync channel for T2 measurements)
function printphoton_t3(
    outfile::IOStream,
    recnum::Integer,
    globalresolution::Float64,
    timetag::Integer,
    channel::Integer,
    dtime::Integer,
)
    # Edited: formatting changed by PK
    @printf(
        outfile,
        "\n%10i CHN %i %18.0f (%0.1f ns) %ich",
        recnum,
        channel,
        timetag,
        (timetag * globalresolution * 1e9),
        dtime
    )
end

function printphoton_t2(
    outfile::IOStream,
    recnum::Integer,
    globalresolution::Float64,
    timetag::Integer,
    channel::Integer,
)
    # Edited: formatting changed by PK
    @printf(
        outfile,
        "\n%10i CHN %i %18.0f (%0.1f ps)",
        recnum,
        channel,
        timetag,
        (timetag * globalresolution * 1e12)
    )

end

# Print Marker
# timetag: Raw timetag from record * globalresolution = Real Time arrival of Photon
# markers: Bitfield of arrived markers, different markers can arrive at same time (same record)
function printmarker(
    outfile::IOStream,
    recnum::Integer,
    globalresolution::Float64,
    timetag::Integer,
    markers::Integer,
)
    # Edited: formatting changed by PK
    @printf(
        outfile,
        "\n%10i MAR %i %18.0f (%0.1f ns)",
        recnum,
        markers,
        timetag,
        (timetag * globalresolution * 1e9)
    )
end

# Print Overflow
# count: Some TCSPC provide Overflow compression = if no Photons between overflow you get one record for multiple Overflows
function printoverflow(outfile::IOStream, recnum::Integer, count::Integer)
    # Edited: formatting changed by PK
    @printf(outfile, "\n%10i OFL * %i", recnum, count)
end

# Decoder functions

# Read PicoHarp T3
#! Not fully modified yet
function readpt3!(
    infile::IOStream,
    outfile::IOStream,
    number_of_records::Integer,
    globalresolution::Float64,
    cnt::Count,
)
    ofltime = 0
    wraparound = 65536

    for recnum = 1:number_of_records
        t3record = read(infile, UInt32)     # all 32 bits:
        #   +-------------------------------+  +-------------------------------+
        #   |x|x|x|x|x|x|x|x|x|x|x|x|x|x|x|x|  |x|x|x|x|x|x|x|x|x|x|x|x|x|x|x|x|
        #   +-------------------------------+  +-------------------------------+
        nsync = t3record & 65535       # the lowest 16 bits:
        #   +-------------------------------+  +-------------------------------+
        #   | | | | | | | | | | | | | | | | |  |x|x|x|x|x|x|x|x|x|x|x|x|x|x|x|x|
        #   +-------------------------------+  +-------------------------------+
        chan = (t3record >>> 28) & 15   # the upper 4 bits:
        #   +-------------------------------+  +-------------------------------+
        #   |x|x|x|x| | | | | | | | | | | | |  | | | | | | | | | | | | | | | | |
        #   +-------------------------------+  +-------------------------------+
        truensync = ofltime + nsync
        if (chan >= 1) && (chan <= 4)
            dtime = (t3record >>> 16) & 4095
            cnt.ph += 1
            printphoton_t3(outfile, recnum, globalresolution, truensync, chan, dtime)  # regular count at Ch1, Rt_Ch1 - Rt_Ch4 when the router is enabled
        elseif chan == 15 # special record
            markers = (t3record >>> 16) & 15 # where these four bits are markers:
            #   +-------------------------------+  +-------------------------------+
            #   | | | | | | | | | | | | |x|x|x|x|  | | | | | | | | | | | | | | | | |
            #   +-------------------------------+  +-------------------------------+
            if markers == 0                           # then this is an overflow record
                ofltime = ofltime + wraparound       #  % and we unwrap the numsync (=time tag) overflow
                cnt.ov += 1
                printoverflow(outfile, recnum, 1)
            else                                    # if nonzero, then this is a true marker event
                cnt.ma += 1
                printmarker(outfile, recnum, globalresolution, truensync, markers)
            end
        else
            @printf(outfile, "Err ")
        end
    end
end

# Read PicoHarp T3 without printing
#! Not fully modified yet
function readpt3!(infile::IOStream, number_of_records::Integer, cnt::Count)
    ofltime = 0
    wraparound = 65536

    for _ = 1:number_of_records
        t3record = read(infile, UInt32)
        nsync = t3record & 65535
        chan = (t3record >>> 28) & 15
        truensync = ofltime + nsync
        if (chan >= 1) && (chan <= 4)
            dtime = (t3record >>> 16) & 4095
            cnt.ph += 1
        elseif chan == 15
            markers = (t3record >>> 16) & 15
            if markers == 0
                ofltime = ofltime + wraparound
                cnt.ov += 1
            else
                cnt.ma += 1
            end
        else
            error("Err")
        end
    end
end

# Read PicoHarp T2
#! Not fully modified yet
function readpt2!(
    infile::IOStream,
    outfile::IOStream,
    number_of_records::Integer,
    globalresolution::Float64,
    cnt::Count,
)
    ofltime = 0
    wraparound = 210698240

    for recnum = 1:number_of_records
        t2record = read(infile, UInt32)
        t2time = t2record & 268435455             #the lowest 28 bits
        chan = (t2record >>> 28) & 15      #the next 4 bits
        timetag = t2time + ofltime
        if (chan >= 0) && (chan <= 4)
            cnt.ph += 1
            printphoton_t2(outfile, recnum, globalresolution, timetag, chan)
        elseif chan == 15
            markers = t2record & 15  # where the lowest 4 bits are marker bits
            if markers == 0                   # then this is an overflow record
                ofltime = ofltime + wraparound # and we unwrap the time tag overflow
                cnt.ov += 1
                printoverflow(outfile, recnum, 1)
            else                            # otherwise it is a true marker
                cnt.ma += 1
                printmarker(outfile, recnum, globalresolution, timetag, markers)
            end
        else
            @printf(outfile, "Err")
        end
        # Strictly, in case of a marker, the lower 4 bits of time are invalid
        # because they carry the marker bits. So one could zero them out.
        # However, the marker resolution is only a few tens of nanoseconds anyway,
        # so we can just ignore the few picoseconds of error.
    end
end

# Read PicoHarp T2 without printing
#! Not fully modified yet
function readpt2!(infile::IOStream, number_of_records::Integer, cnt::Count)
    ofltime = 0
    wraparound = 210698240

    for _ = 1:number_of_records
        t2record = read(infile, UInt32)
        t2time = t2record & 268435455
        chan = (t2record >>> 28) & 15
        timetag = t2time + ofltime
        if (chan >= 0) && (chan <= 4)
            cnt.ph += 1
        elseif chan == 15
            markers = t2record & 15
            if markers == 0
                ofltime = ofltime + wraparound
                cnt.ov += 1

            else
                cnt.ma += 1

            end
        else
            error("Err")
        end

    end
end

# Read HydraHarp/TimeHarp260 T3
function readht3!(
    infile::IOStream,
    outfile::IOStream,
    number_of_records::Integer,
    globalresolution::Float64,
    version::Integer,
    cnt::Count,
    macrotimes::Vector{<:Integer},
    microtimes::Vector{<:Integer},
)
    overflowcorrection = 0
    t3wraparound = 1024

    for recnum = 1:number_of_records
        t3record = read(infile, UInt32)     # all 32 bits:
        #   +-------------------------------+  +-------------------------------+
        #   |x|x|x|x|x|x|x|x|x|x|x|x|x|x|x|x|  |x|x|x|x|x|x|x|x|x|x|x|x|x|x|x|x|
        #   +-------------------------------+  +-------------------------------+
        nsync = t3record & 1023       # the lowest 10 bits:
        #   +-------------------------------+  +-------------------------------+
        #   | | | | | | | | | | | | | | | | |  | | | | | | |x|x|x|x|x|x|x|x|x|x|
        #   +-------------------------------+  +-------------------------------+
        dtime = (t3record >>> 10) & 32767   # the next 15 bits:
        #   the dtime unit depends on "resolution" that can be obtained from header
        #   +-------------------------------+  +-------------------------------+
        #   | | | | | | | |x|x|x|x|x|x|x|x|x|  |x|x|x|x|x|x| | | | | | | | | | |
        #   +-------------------------------+  +-------------------------------+
        channel = (t3record >>> 25) & 63   # the next 6 bits:
        #   +-------------------------------+  +-------------------------------+
        #   | |x|x|x|x|x|x| | | | | | | | | |  | | | | | | | | | | | | | | | | |
        #   +-------------------------------+  +-------------------------------+
        special = (t3record >>> 31) & 1   # the last bit:
        #   +-------------------------------+  +-------------------------------+
        #   |x| | | | | | | | | | | | | | | |  | | | | | | | | | | | | | | | | |
        #   +-------------------------------+  +-------------------------------+
        if special == 0   # this means a regular input channel
            true_nsync = overflowcorrection + nsync
            #  one nsync time unit equals to "syncperiod" which can be
            #  calculated from "SyncRate"
            cnt.ph += 1
            printphoton_t3(outfile, recnum, globalresolution, true_nsync, channel, dtime)
            macrotimes[cnt.ph] = true_nsync
            microtimes[cnt.ph] = dtime
        elseif channel == 63  # overflow of nsync occured
            if (nsync == 0) || (version == 1) # if nsync is zero it is an old style single oferflow or old version
                overflowcorrection = overflowcorrection + t3wraparound
                cnt.ov += 1
                printoverflow(outfile, recnum, 1)
            else         # otherwise nsync indicates the number of overflows - THIS IS NEW IN FORMAT V2.0
                overflowcorrection = overflowcorrection + t3wraparound * nsync
                cnt.ov += nsync
                printoverflow(outfile, recnum, nsync)
            end
        elseif (channel >= 1) && (channel <= 15)  # these are markers
            true_nsync = overflowcorrection + nsync
            cnt.ma += 1
            printmarker(outfile, recnum, globalresolution, true_nsync, channel)
        end
    end
    return macrotimes, microtimes
end

# Read HydraHarp/TimeHarp260 T3 without printing
function readht3!(
    infile::IOStream,
    number_of_records::Integer,
    version::Integer,
    cnt::Count,
    macrotimes::Vector{<:Integer},
    microtimes::Vector{<:Integer},
)
    overflowcorrection = 0
    t3wraparound = 1024

    for _ = 1:number_of_records
        t3record = read(infile, UInt32)
        nsync = t3record & 1023
        dtime = (t3record >>> 10) & 32767
        channel = (t3record >>> 25) & 63
        special = (t3record >>> 31) & 1
        if special == 0
            true_nsync = overflowcorrection + nsync
            cnt.ph += 1
            macrotimes[cnt.ph] = true_nsync
            microtimes[cnt.ph] = dtime
        elseif channel == 63
            if (nsync == 0) || (version == 1)
                overflowcorrection = overflowcorrection + t3wraparound
                cnt.ov += 1
            else
                overflowcorrection = overflowcorrection + t3wraparound * nsync
                cnt.ov += nsync
            end
        elseif (channel >= 1) && (channel <= 15)
            true_nsync = overflowcorrection + nsync
            cnt.ma += 1
        end
    end
    return macrotimes, microtimes
end

# Read HydraHarp/TimeHarp260 T2
#! Not fully modified yet
function readht2!(
    infile::IOStream,
    outfile::IOStream,
    number_of_records::Integer,
    globalresolution::Float64,
    version::Integer,
    cnt::Count,
)
    overflowcorrection = 0
    t2wraparound_v1 = 33552000
    t2wraparound_v2 = 33554432 # = 2^25  IMPORTANT! THIS IS NEW IN FORMAT V2.0

    for recnum = 1:number_of_records
        t2record = read(infile, UInt32)     # all 32 bits:
        #   +-------------------------------+  +-------------------------------+
        #   |x|x|x|x|x|x|x|x|x|x|x|x|x|x|x|x|  |x|x|x|x|x|x|x|x|x|x|x|x|x|x|x|x|
        #   +-------------------------------+  +-------------------------------+
        dtime = t2record & 33554431   # the last 25 bits:
        #   +-------------------------------+  +-------------------------------+
        #   | | | | | | | |x|x|x|x|x|x|x|x|x|  |x|x|x|x|x|x|x|x|x|x|x|x|x|x|x|x|
        #   +-------------------------------+  +-------------------------------+
        channel = (t2record >>> 25) & 63   # the next 6 bits:
        #   +-------------------------------+  +-------------------------------+
        #   | |x|x|x|x|x|x| | | | | | | | | |  | | | | | | | | | | | | | | | | |
        #   +-------------------------------+  +-------------------------------+
        special = (t2record >>> 31) & 1   # the last bit:
        #   +-------------------------------+  +-------------------------------+
        #   |x| | | | | | | | | | | | | | | |  | | | | | | | | | | | | | | | | |
        #   +-------------------------------+  +-------------------------------+
        # the resolution in T2 mode is 1 ps  - IMPORTANT! THIS IS NEW IN FORMAT V2.0
        timetag = overflowcorrection + dtime
        if special == 0   # this means a regular photon record
            cnt.ph += 1
            printphoton_t2(outfile, recnum, globalresolution, timetag, channel + 1)
        elseif channel == 63  # overflow of dtime occured
            if version == 1
                overflowcorrection = overflowcorrection + t2wraparound_v1
                cnt.ov += 1
                printoverflow(outfile, recnum, 1)
            elseif (dtime == 0) # if dtime is zero it is an old style single oferflow
                overflowcorrection = overflowcorrection + t2wraparound_v2
                cnt.ov += 1
                printoverflow(outfile, recnum, 1)
            else         # otherwise dtime indicates the number of overflows - THIS IS NEW IN FORMAT V2.0
                overflowcorrection = overflowcorrection + t2wraparound_v2 * dtime
                cnt.ov += dtime
                printoverflow(outfile, recnum, dtime)
            end
        elseif channel == 0  # Sync event
            cnt.ph += 1
            printphoton_t2(outfile, recnum, globalresolution, timetag, channel)
        elseif (channel >= 1) && (channel <= 15)  # these are markers
            cnt.ma += 1
            printmarker(outfile, recnum, globalresolution, timetag, channel)
        end
    end
end

# Read HydraHarp/TimeHarp260 T2 without printing
#! Not fully modified yet
function readht2!(
    infile::IOStream,
    number_of_records::Integer,
    version::Integer,
    cnt::Count,
)
    overflowcorrection = 0
    t2wraparound_v1 = 33552000
    t2wraparound_v2 = 33554432

    for _ = 1:number_of_records
        t2record = read(infile, UInt32)
        dtime = t2record & 33554431
        channel = (t2record >>> 25) & 63
        special = (t2record >>> 31) & 1
        timetag = overflowcorrection + dtime
        if special == 0
            cnt.ph += 1

        elseif channel == 63
            if version == 1
                overflowcorrection = overflowcorrection + t2wraparound_v1
                cnt.ov += 1

            elseif (dtime == 0)
                overflowcorrection = overflowcorrection + t2wraparound_v2
                cnt.ov += 1

            else
                overflowcorrection = overflowcorrection + t2wraparound_v2 * dtime
                cnt.ov += dtime

            end
        elseif channel == 0
            cnt.ph += 1

        elseif (channel >= 1) && (channel <= 15)
            cnt.ma += 1

        end
    end
end
