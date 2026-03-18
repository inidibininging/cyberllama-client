local Sound = {

}
Sound.EatingSounds = {
    "cmn_generic_male_fat_stand_eat_burger_02",
    "cmn_generic_male_fat_eat_burger",
    "cmn_generic_male_fat_stand_eat_burger_01",
    "cmn_generic_male_eat_generic",
    "generic_work_eat_short",
    "generic_work_eat_long",
    "cmn_generic_male_eat_chrunchy",
    "cmn_generic_male_eat_slurpy",
    "cmn_generic_male_eat_wet",
}

function Sound.PlayRandomEatingSounds()
    local line = math.random(#(Sound.EatingSounds))
    GetPlayer():PlaySoundEvent(Sound.EatingSounds[line])
end

Sound.DrinkingSounds = {
    "cmn_generic_female_drink_swallow",
    "ph_drink_package_plastic",
    "ph_dst_drink_carton",
    "ph_dst_drink_package",
    "q203_sc_05_v_drinks",
    "q000_corpo_sc_01_v_fem_drinks",
    "q000_corpo_sc_03b_v_drinks",
    "sq004_sc_08_panam_drinks",
}
function Sound.PlayRandomDrinkingSounds()
    local line = math.random(#(Sound.DrinkingSounds))
    GetPlayer():PlaySoundEvent(Sound.DrinkingSounds[line])
end

Sound.KissingSoundsFemale = {
    "sq30_sc_09_kiss_02",
    "sq30_sc_09_kiss_01",
    "sq028_sc_05_kiss_01",
    "sq030_sc_10_kiss_02",
    "sq027_sc_9_v_kiss_panam",
    "q203_sc_01_v_kiss_judy",
}
Sound.KissingSoundsMale = {
    "sq30_sc_09_kiss_02",
    "sq30_sc_09_kiss_01",
    "sq028_sc_05_kiss_01",
    "sq030_sc_10_kiss_02",
    "q203_sc_01_v_kiss_river",
    "q203_sc_01_v_kiss_kerry",
    "q115_sc_03_johnny_rogue_kiss_01",
    "q115_sc_03_johnny_rogue_kiss_02",
}
function Sound.PlayKissingSoundsFemaleRandom()
    local line = math.random(#(Sound.KissingSoundsFemale))
    GetPlayer():PlaySoundEvent(Sound.KissingSoundsFemale[line])
end
function Sound.PlayKissingSoundsMaleRandom()
    local line = math.random(#(Sound.KissingSoundsMale))
    GetPlayer():PlaySoundEvent(Sound.KissingSoundsMale[line])
end
function Sound.PlayMenuExitSound()
    GetPlayer():PlaySoundEvent("ui_menu_exit")
end
return Sound