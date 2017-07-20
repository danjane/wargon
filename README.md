# wargon
Playing around with computer chess in julia

```julia
include("wargon.jl")
```

"""
To do:
 - Provide take moves before move moves -> faster alphabeta cutoff?
 - With bitboards, can keep things immutable: generate a new board. Easily track castling etc.
 - bitboard is giving about 40,000,000 movesearch + move [+ takeback] per second
 - Never make a list of available moves. Just generate them and search straight away.
 - Pawn structure evaluator idea: just play pawns forward without pieces.
 - Generate dictionary of knight moves in advance.
===========================
julia> try
          x == 2
       catch err
          f = open("/tmp/bad","w")
          serialize(f, (1,2))
          close(f)
          throw(err)
       end
ERROR: UndefVarError: x not defined
julia> open(deserialize, "/tmp/bad")
===========================
 - immutable Moose
     a::Int
   end
 - import Base.+ 
 - +(m1::Moose, m2::Moose) = Moose(m1.a * m2.a)
 - m = Moose(2)
 - n = Moose(4)
 - m+n 
 - @code_native m+n
 - @code_warntype m+n
===========================
immutable Pieces
   p::UInt8
end
immutable BitBoard
   b::UInt64
end
x = reinterpret(Int, pawns.b)
923847392231271730

pawns = BitBoard(255 << 8)
x = reinterpret(Int, pawns.b)
for inc=1:64
  print(x % 2)
  x = div(x,2)
end
reverse(bin(pawns.b,64))

Use bitwise operators e.g. << to shift pieces around...
===========================
import AMPSPdfs.DTPDFS.PDF
f=PDF([1.],[6],[5 2 .5 1])
function samplevariancetest(f)
    s=Float64[]
    for i=1:1000000
        push!(s,quantile(f,rand()))
    end
  return abs(var(f)/var(s)-1)<0.01
end
samplevariancetest(f)
using ProfileView
@profile samplevariancetest(f)
ProfileView.view()
===========================
 - apply! and takeback! update board piece points for potential speedup
 - Pawn structure, castling, ratio of points and king/rook unmoved board points
 - Blocking pieces and no need to check square is in range
 - En passent + Three-in-a-row rule...
 - Serialize board -> hash table - https://en.wikipedia.org/wiki/Hash_table
 - Get parallel threads running + computer thinking while human is thinking.
 - Null moves + quiescence search
 - Neural net static evaluator
"""
