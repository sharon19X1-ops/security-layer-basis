from rules.ce001 import CE001
from rules.rs001 import RS001
from rules.hitl001 import HITL001
from rules.si002 import SI002

RULE_CHAIN = [CE001(), RS001(), HITL001(), SI002()]
