import Base.show
import Base.print
import Base.string

"""
To do:
- change number representing pieces from 1:32 to 1:16 and 48:64. 17:32 then become white promoted pawns (queens or knights) and 33:63 for black.
- Serialize board. Hash result. Create a dict from hash start to [white_in_check, black_in_check]
- Use a hash table - https://en.wikipedia.org/wiki/Hash_table - storing board evaluations at a given depth.
- Implement mystyle minimax
- disallowcastlerightwhite, disallowcastleftwhite (ints recording move when this occurred)
- currentmove = length(moves) + 1
- only check right castle if e1:f1 and h1:g1 in moves.
- only check left castle if e1:d1 and a1:b1 and a1:c1 in moves.
- Replace minimax with alphabeta
- Pawn promotion.
- 3-in-a-row rule...
- Castling; no castling across check
- Get computer thinking while human is thinking.
- Each evalutation (for each starting point and ply) gets put into the massive hash table.
"""

LEVEL = 4
VERBOSE = false
NOCATCH = false
NOSQ = 65

whitepawn = [9,10,11,12,13,14,15,16]
blackpawn = [17,18,19,20,21,22,23,24]
whiterook = [1,8]
blackrook = [25,32]
whiteknight = [2,7]
blackknight = [26,31]
whitebishop = [3,6]
blackbishop = [27,30]
whitequeen = [4]
blackqueen = [28]
whiteking = [5]
blackking = [29]

type move
  from::Int8
  to::Int8
  takes::Int8
end

type board
  squares::Array{Int8,1}
  pieces::Array{Int8,1}
  whitesmove::Bool
  disallowcastling::Array{Bool,1}
  moves::Array{move,1}
end

print(io::IO, b::board) = show(io, b)
show(io::IO, b::board) = print(io, b)

function newboard()
  squares = [collect(1:16); NOSQ*ones(Int32,32); collect(17:32)]
  pieces = [collect(1:16); collect(49:64); zeros(33)]
  whitesmove = true
  disallowcastling = [false,false,false,false]
  moves = Array{move,1}()
  board(squares,pieces,whitesmove,disallowcastling,moves)
end

function apply!(b::board, m::move)
  b.pieces[b.squares[m.from]]=m.to
  b.pieces[m.takes]=NOSQ
  b.squares[m.to]=b.squares[m.from]
  b.squares[m.from]=NOSQ
  b.whitesmove = !b.whitesmove
  push!(b.moves, m)
  return
end

function value(b)
  values = [5;3;3;9;1000;3;3;5;ones(Int32,8);-ones(Int32,8);-5;-3;-3;-9;-1000;-3;-3;-5;zeros(Int,33)]
  return sum(values[b.pieces .!= NOSQ]) + sum(ifelse.(b.pieces[9:16].>64, 8, 0)) + sum(ifelse.(b.pieces[17:24].>64, -8, 0))
end

up = (x) -> begin
  (x<1||x>64) && return 0
  x+8>65 && return 0
  x+8
end
down = (x) -> begin
  (x<1||x>64) && return 0
  max(x-8,0)
end
left = (x) -> begin
  (x<1||x>64) && return 0
  mod(x-1,8)==0 && return 0
  x-1
end
right = (x) -> begin
  (x<1||x>64) && return 0
  mod(x+1,8)==1 && return 0
  x+1
end
upLeft = (x) -> begin
  (x<1||x>64) && return 0
  mod(x-1,8)==0 && return 0
  x+8>65 && return 0
  x+7
end
upRight = (x) -> begin
  (x<1||x>64) && return 0
  x+8>65 && return 0
  mod(x+1,8)==1 && return 0
  x+9
end
downLeft = (x) -> begin
  (x<1||x>64) && return 0
  mod(x-1,8)==0 && return 0
  max(x-9,0)
end
downRight = (x) -> begin
  (x<1||x>64) && return 0
  mod(x+1,8)==1 && return 0
  max(x-7,0)
end
upUpLeft = (x) -> up(up(left(x)))
upUpRight = (x) -> up(up(right(x)))
upLeftLeft = (x) -> up(left(left(x)))
upRightRight = (x) -> up(right(right(x)))
downLeftLeft = (x) -> down(left(left(x)))
downRightRight = (x) -> down(right(right(x)))
downDownLeft = (x) -> down(down(left(x)))
downDownRight = (x) -> down(down(right(x)))

pawnUnmoved = (p,b) -> (9<=p<=16 && b.pieces[p]==p) || (16<p<25 && b.pieces[p]==p+32)

pieces = Dict(1=>"wR",2=>"wN",3=>"wB",4=>"wQ",5=>"wK",6=>"wB",7=>"wN",8=>"wR",
              9=>"wP",10=>"wP",11=>"wP",12=>"wP",13=>"wP",14=>"wP",15=>"wP",16=>"wP",
             17=>"bP",18=>"bP",19=>"bP",20=>"bP",21=>"bP",22=>"bP",23=>"bP",24=>"bP",
             25=>"bR",26=>"bN",27=>"bB",28=>"bQ",29=>"bK",30=>"bB",31=>"bN",32=>"bR",
             NOSQ=>"  ",0=>"  ")
row(x) = div((x-1)%64,8)+1
col(x) = mod((x-1)%64,8)+1
isempty(x, board) = 0<x<65 && board.squares[x]==NOSQ
iswhite(x, board) = 0<x<65 && 0<board.squares[x]<17
isblack(x, board) = 0<x<65 && 16<board.squares[x]<NOSQ

# sring manipulations down here
colstr(x) = ["A","B","C","D","E","F","G","H"][col(x)]
colnum(x) = parse(Int, x) - 9
rowstr(x) = string(row(x))
square(x) = string(colstr(x),rowstr(x))
isopposite(whitesmove, x, b) = ifelse(whitesmove, isblack(x, b), iswhite(x, b))
isblack(piece) = piece[1]=='b'
iswhite(piece) = piece[1]=='w'

function tomove(b::board)
  function _tomove(m)
    if length(m)==4
      m=string(m[1:2],":",m[3:4])
    end
    fromcol,fromrow,tocol,torow = colnum(m[1]),parse(Int,m[2]),colnum(m[4]),parse(Int,m[5])
    from = fromcol + 8*(fromrow-1)
    to = tocol + 8*(torow-1)
    return move(from,to,b.squares[to])
  end
end

function pawnMoves(b::board; whitesmove=b.whitesmove)
  moves = []
  inc = ifelse(whitesmove, up, down)
  pieces=ifelse(whitesmove, whitepawn, blackpawn) 
  for piece in pieces
    from = b.pieces[piece]
    to = inc(from)
    if isempty(to,b)
      push!(moves,move(from,to,NOSQ))
      to = inc(to)
      if pawnUnmoved(piece,b) && isempty(to,b)
        push!(moves,move(from,to,NOSQ))
      end
    end
    for to in [inc(left(from)), inc(right(from))]
      if isopposite(whitesmove,to,b)
        push!(moves,move(from,to,b.squares[to]))
      end
    end
  end
  moves
end

function knightMoves(b::board; whitesmove=b.whitesmove)
  moves = move[]
  pieces = ifelse(whitesmove, whiteknight, blackknight)
  for piece in pieces
    from = b.pieces[piece]
    for m in [upUpLeft upUpRight upLeftLeft upRightRight downLeftLeft downRightRight downDownLeft downDownRight]
      to = m(from)
      if isempty(to,b)
        push!(moves,move(from,to,NOSQ))
      elseif isopposite(whitesmove,to,b)
        push!(moves,move(from,to,b.squares[to]))
      end
    end
  end
  moves
end

function crossboard(b::board, pieces, whitesmove, increments, multistep)
  moves = move[]
  for piece in pieces
    from = b.pieces[piece]
    for inc in increments
      to = from
      while true
        to = inc(to)
        if isempty(to,b)
          push!(moves, move(from,to,NOSQ))
          if !multistep
            break
          end
        elseif isopposite(whitesmove,to,b)
          push!(moves,move(from,to,b.squares[to]))
          break
        else
          break
        end
      end
    end
  end
  return moves
end

function rookMoves(b::board; whitesmove=b.whitesmove)
    pieces = ifelse(whitesmove, whiterook, blackrook)
    increments = [up down left right]
    crossboard(b, pieces, whitesmove, increments, true)
end

function bishopMoves(b::board; whitesmove=b.whitesmove)
    pieces = ifelse(whitesmove, whitebishop, blackbishop)
    increments = [upLeft upRight downLeft downRight]
    crossboard(b, pieces, whitesmove, increments, true)
end

function queenMoves(b::board; whitesmove=b.whitesmove)
    pieces = ifelse(whitesmove, whitequeen, blackqueen)
    increments = [up down left right upLeft upRight downLeft downRight]
    crossboard(b, pieces, whitesmove, increments, true)
end

function kingMoves(b::board; whitesmove=b.whitesmove)
    pieces = ifelse(whitesmove, whiteking, blackking)
    increments = [up down left right upLeft upRight downLeft downRight]
    crossboard(b, pieces, whitesmove, increments, false)
end

function possiblemoves(b::board)
  moves = [pawnMoves(b); rookMoves(b); knightMoves(b); 
           bishopMoves(b); queenMoves(b); kingMoves(b)]
end

function takeback!(b::board)
  m = pop!(b.moves)
  undo = move(m.to,m.from,NOSQ)
  taken = m.takes
  apply!(b, undo)
  pop!(b.moves)
  if taken != NOSQ
    b.pieces[taken] = undo.from
    b.squares[undo.from] = taken
  end
end

function incheck(b::board, white)
    whitesmove = b.whitesmove
    k = ifelse(white, 5, 29)
    b.whitesmove = ifelse(white, false, true)
    for m in possiblemoves(b)
        if m.to == b.pieces[k]
            b.whitesmove = whitesmove
            return true
        end
    end
    b.whitesmove = whitesmove
    return false
end

function intocheck(b::board, m::move)
    apply!(b, m)
    result = incheck(b, !b.whitesmove)
    takeback!(b)
    return result
end

function allowedmoves(b::board)
    [m for m in possiblemoves(b) if !(intocheck(b, m))]
end 

function minimax(b::board, depth; moves=move[])
  if length(moves)==0
    moves = shuffle(possiblemoves(b))
  end
  if depth == 0 || length(moves) == 0
    score = ifelse(b.whitesmove, 1, -1) * value(b)
    return move(0, 0, NOSQ), score
  end
  bestmove, bestscore = move(0, 0, NOSQ), -Inf
  for m in moves
    apply!(b, m)
    s = -minimax(b, depth-1)[2]
    if VERBOSE
      println(depth," :  ","    "^(3-depth),show(m), " : ", s)
    end
    if s > bestscore
      bestmove, bestscore = m, s
    end
    takeback!(b)
  end
  return bestmove, bestscore
end

function alphabeta(bi::board, depth, α, β, whitesmove; moves=move[])
  if length(moves)==0
    moves = shuffle(possiblemoves(bi))
  end
  if depth == 0
    return move(0, 0, NOSQ), value(bi)
  end
  if whitesmove
    mb, v = move(0, 0, NOSQ), -Inf
    for mi in moves
      apply!(bi, mi)
      assert(bi.whitesmove==false)
      mr, s = alphabeta(bi,depth-1,α,β,false)
      takeback!(bi)
      if s > v
        v, mb = s, mi
      end
      α = max(α, v)
      if β <= α
        break
      end
    end
    if VERBOSE
      try
        println("HERE 1 ",depth," :  ","    "^(3-depth),show(mb), " : ", v, " α=$α β=$β")
      catch
      end
    end
    return mb, v
  else
    mb, v = move(0, 0, NOSQ), +Inf
    for mi in moves
      apply!(bi, mi)
      assert(bi.whitesmove==true)
      mr, s = alphabeta(bi,depth-1,α,β,true)
      takeback!(bi)
      if s < v
        v, mb = s, mi
      end
      β = min(β, v)
      if β <= α
        break
      end
    end
    if VERBOSE
      try
        println("HERE 2 ",depth," :  ","    "^(3-depth),show(mb), " : ", v, " α=$α β=$β")
      catch
      end
    end
    return mb, v
  end
end

function input(prompt::AbstractString="")
  print(prompt)
  chomp(readline())
end

function showmoves(b::board)
    moves = map(show,allowedmoves(b))
    join(moves,", ")
end

function prnt(piece)
  if iswhite(piece)
    print_with_color(:blue, "$piece ")
  else
    print_with_color(:red, "$piece ")
  end
end

function show(board::board)
  taken = find((x)->x==NOSQ,b.pieces[1:32])
  blackTaken = [pieces[x] for x in taken[taken.>16]]
  whiteTaken = [pieces[x] for x in taken[taken.<17]]
  blackPrisoners = join(whiteTaken,", ")
  whitePrisoners = join(blackTaken,", ")
  print_with_color(:red,"\n   =========================\n")
  for row in 8:-1:1
    print_with_color(:blue, "$row | ")
    for col in 1:8
      #println(row," ",col," ",col+(row-1)*8," ",b.squares[col+(row-1)*8])
      piecestr = pieces[b.squares[col+(row-1)*8]]
       if piecestr=="  " 
         if (row+col)%2 == 0
           print(":: ")
         else
           print("   ")
         end
       else
         prnt(piecestr)
       end
    end
    print_with_color(:red, "| ")
    if row==1
      print_with_color(:red, "      ", whitePrisoners)
    elseif row==8
      print_with_color(:blue, "      ", blackPrisoners)
    end
    println("")
  end
  print_with_color(:blue,"   =========================\n")
  print_with_color(:blue,"     A  B  C  D  E  F  G  H  \n")
  print(ifelse(board.whitesmove, "\nWhite to move. ", "\nBlack to move. "))
end

function show(io::IO, b::board)
  show(b)
  print("$(length(allowedmoves(b))) available moves: \n  $(showmoves(b))\n")
end

show(m::move) = string(square(m.from),ifelse(m.takes!=NOSQ,"x",":"),square(m.to))

function checkmate(b)
    winner = ifelse(!b.whitesmove,"WHITE","BLACK")
    return "$winner WINS!"
end

function play(b; autoplay=false)
  while true
    b2 = deepcopy(b)
    allowed = allowedmoves(b)
    try
      if !autoplay && b.whitesmove
        print(b)
        if length(allowed) == 0
           return checkmate(b)
        end
        mstr = input("\n> ")
        assert(mstr in map(show, allowed))
        m = tomove(b)(mstr)
        apply!(b, m)
      end
      print(b)
      b2 = deepcopy(b)
      allowed = allowedmoves(b2)
      tic = time()
      if length(allowed) == 0
         return checkmate(b2)
      end
      #m, s = minimax(b2, LEVEL; moves=shuffle(allowed))
      m, s = alphabeta(b2, LEVEL, -Inf, Inf, b2.whitesmove; moves=shuffle(allowed))
      toc = time()
      elapsed = Base.Dates.Second(round(toc-tic))
      print("\n> ",show(m)," elapsed time: $elapsed\n")
      sleep(1)
      apply!(b,m)
    catch e
      if NOCATCH
        throw(e)
      end
      print(b)
      if isa(e, InterruptException)
        println("Breaking out of game")
        break
      end
      println("Incorrect move. Try again...")
    end
  end
end

b = newboard()
play(b, autoplay=false)
