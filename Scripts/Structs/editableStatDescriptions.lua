local oldGame = structs.f.GameStructure
function structs.f.GameStructure(define, ...)
    oldGame(define, ...)
    local cs = const.Stats
    define[0x56B7E8].union("ExtraStatDescriptions") -- random address
    .EditPChar(cs.HP)
    .EditPChar(cs.SP)
    .EditPChar(cs.ArmorClass)
    .skip(12)
    .EditPChar(cs.Level)
    .skip(4)
    .EditPChar(cs.MeleeAttack)
    .EditPChar(cs.MeleeDamageBase)
    .EditPChar(cs.RangedAttack)
    .EditPChar(cs.RangedDamageBase)
    .EditPChar(cs.FireResistance)
    .EditPChar(cs.ElecResistance)
    .EditPChar(cs.ColdResistance)
    .EditPChar(cs.PoisonResistance)
    .EditPChar(cs.MagicResistance)
    .union()
end