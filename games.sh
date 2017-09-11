games="n lb2 lc1 lc3 ma1 mb1 lb1
n lb2 lc1 la1 mc3 a1c3 ma1 b2a1 lb2 ma3 c1a3 mc1 sc2 sb1
m sb2 lb2 sc3 lc3 ma1 c3a1 mc3 b2c3 lb2 ma3 la3 mc1 b2c1
n lb2 sc3 lc3 ma1 mb3 lb3 mb1 lb1 sc2 mc1
n lb2 sc3 lc1 ma3 mb3 lb3
n lb2 la3 la1 mc3 a1c3 la1 ma2 a3a2 ma3 a1a3 b2a1 mb2 sc2 sc1
n lb2 la1 lc1 ma3 c1a3 mc1 b2c1 lb2 sc3 b2c3 mb2
n lb2 lc3 lc1 ma3 c1a3 sc1 mc1
m sb2 lb2 sc3 lc1 la3 c1b3 lb1 sa2 ma2 b2a2 mc1
n lb2 sc3 lc3 la1 mb3 ma3 sb1
m sb2 lb2 sc3 lc1 ma3 c1a3 mc1 mc3 lc3 a3c1 lb3
m sb2 lb2 sc3 lc1 ma3 c1a3 mc1 mc3 lc3
n lb2 sc3 la3 mc1 a3c2 ma2 b2c1 lc3 ma1 la1 c2a2 sb2
n lb2 sc3 lc3 ma1 c3a1 lc3 sb1 lb1 ma2 c3a2 mc3
m sb2 la1 lc1 lb2 mc3 a1c3 ma1 c3b1 sc2
n lb2 sc3 lc1 ma3 c1a3 lc1 mc3 lc3 b2c2 mb2 sb3 sa1"

echo "$games" | while read -r a; do
  echo $a
  ./gobblet-gobblers $a
  echo -------------------
done
