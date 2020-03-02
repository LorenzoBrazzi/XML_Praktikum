xquery version "3.0";


module namespace dealer = "bj/dealer";
import module namespace player = "bj/player" at "player.xqm";
import module namespace game = "bj/game" at "game.xqm";

declare variable $dealer:games := db:open("games")/games;

declare
%updating
function dealer:drawCard($gameID as xs:string) {
    let $hand := $dealer:games/game[id = $gameID]/dealer/currentHand
    let $card := game:drawCard($gameID)
    let $val := dealer:calculateDealerValue($gameID)

    return (
        if ($val < 17) then (
            insert node $card as first into $hand,
            game:popDeck($gameID)
        )
        else ()
    )
};

(:Ass wird zunächst als 10 gewertet, solange bis der wert 21 überschreiter, dann zählt es als 1 weiter:)
declare
%private
function dealer:helperSum($acc as xs:integer, $x as xs:string) as xs:integer {
    if ($x= 'A') then (
        if (($acc + 11) > 21) then (
            let $res := $acc + 1
            return $res
        ) else (
            let $res := $acc + 11
            return $res
        )
    ) else if (($x = 'K') or ($x = 'D') or ($x = 'B')) then (
        let $res := $acc + 10
        return $res
    ) else (
        let $res := $acc + xs:integer($x)
        return $res
    )
};

declare function dealer:calculateDealerValue($gameID as xs:string) as xs:integer{
    let $hand := $dealer:games/game[id = $gameID]/dealer/currentHand
    (:Kopie des Elements um zu folden:)
    let $h := ( copy $c := $hand
    modify ()
    return $c)
    (:Fold auf alle Karten des Dealers mit der helperFunction:)
    let $sum := fn:fold-left($h/card, 0, function($acc, $c) {dealer:helperSum($acc, $c/value)})

    return $sum
};

declare
%updating
function dealer:drawCards($gameID as xs:string) {
    let $hand := $dealer:games/game[id = $gameID]/dealer/currentHand
    let $deck := game:getDeck($gameID)

    return
        for $i in (1, 2)
        return (insert node $deck/card[1] as first into $hand,
        delete node $deck/card[1])

};

declare
%updating
function dealer:turnCard($gameID as xs:string){
    let $hand := $dealer:games/game[id = $gameID]/dealer/currentHand
    let $cards := $hand/card
    for $i in $cards
    return replace value of node $i/hidden with false()
};

declare
%updating
function dealer:setInsurance($gameID as xs:string){
    let $hand := $dealer:games/game[id = $gameID]/dealer/currentHand
    let $cards := $hand/card
    return (
    (:Aktiviere die Insurance Funktion, sobald die erste Karte ein Ass ist:)
    if ($cards[1]/value = "A")
    then (
        replace value of node $dealer:games/game[id = $gameID]/dealer/isInsurance with true(),
        (:Sollte die folgende Karte ein Zehner Value sein, hat der Dealer natürlich einen Blackjack:)
        (if (($cards[2]/value = "K") or ($cards[2]/value = "Q") or ($cards[2]/value = "B") or ($cards[2]/value = "10"))
        then (
                replace value of node $dealer:games/game[id = $gameID]/dealer/bj with true()
            ) else ())
    )
    else (
        replace value of node $dealer:games/game[id = $gameID]/dealer/isInsurance with false()
    )
    )
};
