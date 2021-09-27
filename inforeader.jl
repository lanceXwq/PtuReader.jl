using Printf

# strip + read = strid
strid(s::IOStream, nb::Integer) = strip(String(read(s, nb)), '\0')

function getheader(infile::IOStream, headername::String)
    headerfile = open(headername, "w")

    magic = strid(infile, 8)
    magic == "PQTTTR" || error("Magic invalid, this is not an PTU file.")

    tagversion = strid(infile, 8)
    @printf(headerfile, "Tag Version: %s\n", tagversion)

    tagdict = Dict{String,Any}()
    while true
        tagident = strid(infile, 32)
        tagidx = read(infile, Int32)
        tagtyp = read(infile, UInt32)
        evalname = tagident
        tagidx > -1 && evalname *= "(" * string(tagidx + 1) * ")"
        @printf(headerfile, "\n%-40s", evalname)
        if tagtyp == ty_empty8
            read(infile, Int64)
            @printf(headerfile, "<Empty>")
            merge!(tagdict, Dict(evalname => nothing))
        elseif tagtyp == ty_bool8
            tagint = read(infile, Int64)
            if tagint == 0
                @printf(headerfile, "False")
                merge!(tagdict, Dict(evalname => false))
            else
                @printf(headerfile, "True")
                merge!(tagdict, Dict(evalname => true))
            end
        elseif tagtyp == ty_int8
            tagint = read(infile, Int64)
            @printf(headerfile, "%d", tagint)
            merge!(tagdict, Dict(evalname => tagint))
        elseif tagtyp == ty_bitset64
            tagint = read(infile, Int64)
            @printf(headerfile, "%X", tagint)
            merge!(tagdict, Dict(evalname => tagint))
        elseif tagtyp == ty_color8
            tagint = read(infile, Int64)
            @printf(headerfile, "%X", tagint)
            merge!(tagdict, Dict(evalname => tagint))
        elseif tagtyp == ty_float8
            tagfloat = read(infile, Float64)
            @printf(headerfile, "%e", tagfloat)
            merge!(tagdict, Dict(evalname => tagfloat))
        elseif tagtyp == ty_tdatetime
            tagfloat = read(infile, Float64)
            tagtime = Int(round((tagfloat - 25569) * 86400))
            tagtime = Dates.unix2datetime(tagtime) # TODO better datetime format
            write(headerfile, string(tagtime))
            merge!(tagdict, Dict(evalname => tagtime))
        elseif tagtyp == ty_float8array
            tagint = read(infile, Int64)
            @printf(headerfile, "<Float array with %d Entries>", tagint / 8)
            skip(infile, tagint)
        elseif tagtyp == ty_ansistring
            tagint = read(infile, Int64)
            tagstring = strid(infile, tagint)
            @printf(headerfile, "%s", tagstring)
            tagidx > -1 && evalname = tagident * "{" * string(tagidx + 1) * "}"
            merge!(tagdict, Dict(evalname => tagstring))
        elseif tagtyp == ty_widestring
            tagint = read(infile, Int64)
            tagstring = strid(infile, tagint)
            @printf(headerfile, "%s", tagstring)
            tagidx > -1 && evalname = tagident * "{" * string(tagidx + 1) * "}"
            merge!(tagdict, Dict(evalname => tagstring))
        elseif tagtyp == ty_binaryblob
            tagint = read(infile, Int64)
            @printf(headerfile, "<Binary Blob with %d Bytes>", tagint)
            skip(infile, tagint)
            merge!(tagdict, Dict(evalname => tagint))
        else
            error("Illegal Type identifier found! Broken file?")
        end

        tagident == "Header_End" && break
    end
    close(headerfile)
    return tagdict
end


function getdatatype(tttr_rectype::Integer)
    if tttr_rectype == rt_picoharp_t3
        ist2 = false
        println("PicoHarp T3 data")
    elseif tttr_rectype == rt_picoharp_t2
        ist2 = true
        println("PicoHarp T2 data")
    elseif tttr_rectype == rt_hydraharp_t3
        ist2 = false
        println("HydraHarp V1 T3 data")
    elseif tttr_rectype == rt_hydraharp_t2
        ist2 = true
        println("HydraHarp V1 T2 data")
    elseif tttr_rectype == rt_hydraharp2_t3
        ist2 = false
        println("HydraHarp V2 T3 data")
    elseif tttr_rectype == rt_hydraharp2_t2
        ist2 = true
        println("HydraHarp V2 T2 data")
    elseif tttr_rectype == rt_timeharp_260n_t3
        ist2 = false
        println("TimeHarp260N T3 data")
    elseif tttr_rectype == rt_timeharp_260n_t2
        ist2 = true
        println("TimeHarp260N T2 data")
    elseif tttr_rectype == rt_timeharp_260p_t3
        ist2 = false
        println("TimeHarp260P T3 data")
    elseif tttr_rectype == rt_timeharp_260p_t2
        ist2 = true
        println("TimeHarp260P T2 data")
    elseif tttr_rectype == rt_multiharp_t3
        ist2 = false
        println("MultiHarp T3 data")
    elseif tttr_rectype == rt_multiharp_t2
        ist2 = true
        println("MultiHarp T2 data")
    else
        error("Illegal RecordType!")
    end
    return ist2
end