using Printf
using Dates
using Gtk

include("consts.jl")
include("types.jl")
include("inforeader.jl")
include("signalreader.jl")

@views shorten(A::Vector, N::Integer) = A[1:N]

function main()
    #fullname =
    #    open_dialog("Pick a PTU file", GtkNullContainer(), ("*.ptu",), select_multiple = false)
    fullname = "/home/lancexwq/Dropbox (ASU)/graphen+DOPC/Graphene+10nmSiO2+DOPC-suv-50nm-atto655_6e5.ptu"
    #pathname, filename = rsplit(fullname, "/"; limit = 2)


    infile = open(fullname, "r")
    outfile = nothing
    #outfile = open(fullname[1:end-4] * ".jlout", "w")

    tagdict = getheader(infile, fullname[1:end-4] * ".header") # TODO change headername
    ist2 = getdatatype(tagdict["TTResultFormat_TTTRRecType"])

    @printf("\nWriting data to %s", fullname[1:end-4] * ".jlout")
    @printf("\nThis may take a while...")
    if !isnothing(outfile)
        if ist2
            @printf(outfile, "  record# Type Ch        TimeTag             TrueTime/ps\n")
        else
            @printf(
                outfile,
                "  record# Type Ch        TimeTag             TrueTime/ns            DTime\n"
            )
        end
    end

    number_of_records = tagdict["TTResult_NumberOfRecords"]
    rectype = tagdict["TTResultFormat_TTTRRecType"]

    cnt = Count(0, 0, 0)
    macrotimes = Vector{Int64}(undef, number_of_records)
    microtimes = Vector{Int16}(undef, number_of_records)

    if rectype == rt_picoharp_t3
        readpt3!(infile, number_of_records, cnt)
    elseif rectype == rt_picoharp_t2
        readpt2!(infile, number_of_records, cnt)
    elseif rectype == rt_hydraharp_t3
        readht3!(infile, number_of_records, 1, cnt, macrotimes, microtimes)
    elseif rectype == rt_hydraharp_t2
        readht2!(infile, number_of_records, 1, cnt)
    elseif rectype == rt_multiharp_t3 ||
           rectype == rt_hydraharp2_t3 ||
           rectype == rt_timeharp_260n_t3 ||
           rectype == rt_timeharp_260p_t3
        readht3!(infile, number_of_records, 2, cnt, macrotimes, microtimes)
    elseif rectype == rt_multiharp_t2 ||
           rectype == rt_hydraharp2_t2 ||
           rectype == rt_timeharp_260n_t2 ||
           rectype == rt_timeharp_260p_t2
        readht2!(infile, number_of_records, 2, cnt)
    else
        error("Illegal RecordType!")
    end

    close(infile)
    isnothing(outfile) || close(outfile)

    return tagdict, cnt, shorten(macrotimes, cnt.ph), shorten(microtimes, cnt.ph)
end

@time tagdict, cnt, macrotimes, microtimes = main()
