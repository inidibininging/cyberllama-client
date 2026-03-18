local adjectives = {
"Neon",
"Viral",
"Digital",
"Crimson",
"Rusted",
"Ghost",
"Steel",
"Rewired",
"Silent",
"Chromed",
"Circuit",
"Shattered",
"Blighted",
"Voltage",
"Synthetic",
"Holo",
"Echo",
"Broken",
"Radical",
"Wired",
"Toxic",
"Corrupted",
"Infernal",
"Darknet",
"Rogue",
"Neural",
"Obsidian",
"Phantom",
"Augmented",
"Binary",
"Void",
"Rust",
"Shattered",
"Rogue",
"Feral",
"Vexed",
"Hacker",
"Coded",
"Ghosted",
"Plasma",
"Fractured",
"Surge",
"Wraith",
"Eclipse",
"Exiled",
"Glitched",
"Encrypted",
"Infernal",
"Fractured",
"Tainted",
"Oblivion",
"Vengeful",
"Savage",
"Hollow",
"Incendiary",
"Bitter",
"Neural",
"Spectral",
"Oblivion",
"Shadowy",
"Merciless",
"High-tech",
"Rogue",
"Unpredictable",
"Brutal",
"Insurgent",
"Cunning",
"Shadow network",
"Radical",
"Ferocious",
"Infiltrated",
"Deceptive",
"Hostile",
"Exiled",
}

local nouns = {
"Organization",
"Regime",
"Arsenal",
"Agent",
"Alliance",
"Assault",
"Rebellion",
"Trader",
"Syndicate",
"Movement",
"Beast",
"Embassy",
"Smuggler",
"Occupation",
"Refugee",
"Assault",
"Rebellion",
"Trader",
"Syndicate",
"Movement",
"Beast",
"Embassy",
"Smuggler",
"Occupation",
"Refugee",
"Insurrection",
"Infiltrator",
"Scavenger",
"Outlaw",
"Revolt",
"Enclave",
"Hive",
"Corporation",
"Spectrum",
"Cell",
"Resistance",
"Factory",
"Network",
"Agent",
"Commander",
"Terrorist",
"Crew",
"Revolution",
"Cartel",
"Anarchist",
"Bandit",
"Infiltrator",
"Patrol",
"Underworld",
"Militia",
"Protest",
"Rogue State",
"Sector",
"Cellblock",
"Outpost",
"Brotherhood",
"Hacker",
"Inquisitor",
"Cabal",
"Propaganda",
"Enforcer",
"Shadow",
"Revolutionary",
"Gangster",
"Sentinel",
"Chieftain",
"Saboteur",
"Vigilante",
"Thug",
"Crisis",
"Undercity",
"Crime Lord",
"Cybernetic Outcast",
"Rebel Leader",
"Smuggler's Guild",
"Revolutionary Army",
"Mercenary Company",
"Gang of Shadows",
"Insurgent Front",
"Corporation Spy",
"Black Market Trader",
"Terrorist Network",
"Militia Squad",
"Cult Leader",
"Street Samurai",
"Fjord",
"Gargoyle",
"Saffron",
"Banshee",
"Llama",
"Cathedral",
"Nebula",
"Paprika",
"Glacier",
"Mantis",
"Rouge",
"Quasar",
"Witchwood",
"Sage",
"Molten",
"Kelpie",
"Boudoir",
"Galleon",
"Khthonic",
"Kraelion",
"Vorgath",
"Throkos",
"Xandros",
"Kratos",
"Pyrrhic",
"Kaldor",
"Thrakos",
"Morkoth",
"Nefaria",
"Khyron",
"Gorthok",
"Xeridian",
"Thrakkor",
"Vorgalys",
"Kraelkorvath",
"Thrakkaros",
"Khthonixys",
"Zha'thikor",
"Pyrrhexar",
"Morkyraxys",
"Kaldokianus",
"Throkosaur",
"Gorthokrax",
"Nefarionyx",
"Khyronixys",
"Xeridionys",
"Massacre",
"Inquisition",
"Assassination",
"Carnage",
"Slaughterhouse",
"Torture Chamber",
"Battlefield",
"Bloodshed",
"Reckoning",
"Vengeance",
"Annihilation",
"Martyrdom",
"Genocide",
"Executions",
"Inferno",
"Pogrom",
}

Gangs = {
    data = {
        {
          temp = false,
          name='arasaka',
          zones = {
            {name = 'Downtown'},
            {name = 'Watson'},
            {name = 'WestBrook'},
          },
          entities = {}
        },
        {
          temp = false,
          name='animal',
          zones = {
            {name = 'Pacifica'},
            {name = 'Watson'}
          },
          entities = {}
        },
        { 
          temp = false,
          name='aldecaldo',
          zones = {
            {name='Badlands'},
            {name='Watson'}
          }
        },
        { 
          temp = false,
          name='scavenger',
          zones = {
            { name = 'Pacifica' },
            { name = 'Westbrook' },
            { name = 'Watson'}
          },
          entities = {}
        },
        { 
          temp = false,
          name='maelstrom',
          zones = {
            { name = 'Watson' }
          }
        },
        { 
          temp = false,
          name='wraith',
          zones = {
            { name = 'Badlands' }
          },
          entities = {}
        },
        { 
          temp = false,
          name='cyberpunk',
          zones = {
            { name = 'Watson' },
            { name = 'Westbrook' },
            { name = 'Downtown'},
          }
        },
        { 
          temp = false,
          name='tyger',
          zones = {
            { name = 'Watson' },
            { name = 'Westbrook' },
            { name = 'Downtown'},
          },
          entities = {}
        },
        { 
          temp = false,
          name='6thstreet',
          zones = {
            { name = 'Santo Domingo' }
          },
          entities = {}
        },
        { 
          temp = false,
          name='valentino',
          zones = {
            { name = 'Heywood' }
          },
          entities = {}
        },
        {
          name='mox',
          zones = {
            { name = 'Watson' }
          },
          entities = {}
        },
        {
          temp = false,
          name='voodoo',
          zones = {
            { name = 'Pacifica' }
          },
          entities = {}
        },
        {
          temp = false,
          name='militech',
          zones = {
            {name = 'Badlands'},
            {name = 'Downtown'},
            {name = 'Watson'},
          },
          entities = {}
        },
        {
          temp = false,
          name='kangtao',
          zones = {
            {name = 'Downtown'},
            {name = 'Heywood'},
            {name = 'WestBrook'},
          },
          entities = {}
        },
        -- total randomness
        {
          temp = false,
          name='generic',
          zones = {},
          entities = {}
        },
        { 
          name='traumateam',
          entities = {
            zones = {
              {name = 'Downtown'},
              {name = 'Watson'},
              {name = 'WestBrook'},
              {name = 'Heywood'},
            },
          }
        },
        { 
          name='zetatech',
          entities = {
            zones = {
              zones = {
                {name = 'Downtown'},
                {name = 'Watson'},
                {name = 'WestBrook'},
                {name = 'Heywood'},
              },
            }
          }
        },
    }
  }
function Gangs.Init(tryDecodeJson)
  -- Gangs.data = {}
  -- local districtsLen = #Gangs[gidx].name
  local gangsLen = #(Gangs.data)
  print("Gangs: loaded: " .. tostring(gangsLen))
  for gidx = 1, gangsLen do
    local gName = Gangs.data[gidx].name
    -- load only non temp from factions directory
    if Gangs.data[gidx].temp == false then
      local f = assert(io.open("./factions/" .. gName .. ".json"))
      local lines = ''
      lines = f:read("*a")
      local tableDis = {}
      tableDis = tryDecodeJson(lines, f, gName .. ".json")
      print('InitGangEntityInfo ' .. gName)
      Gangs.data[gidx].entities = tableDis
    end
  end
  
end


-- function Gangs.AddGeneric(tryDecodeJson)
--   local gangsLen = #(Gangs.data)
--   for gidx = 1, gangsLen do
--     local gName = Gangs.data[gidx].name
--     if gName == "generic" then
--       local f = assert(io.open("./factions/generic.json"))
--       local lines = ''
--       lines = f:read("*a")
--       local tableDis = {}
--       tableDis = tryDecodeJson(lines, f, "generic.json")
--       print('InitGangEntityInfo ' .. gName)
--       Gangs.data[gidx].entities = tableDis
--     end
--   end
-- end


function Gangs.CreateGang(gangName, stringMatchFilter, zonesArray)
  print("Gangs.CreateGang")
  local gangsLen = #(Gangs.data)
  print("Gangs" .. tostring(gangsLen))
  local mercs = {
    temp = true,
    name=gangName,
    zones = zonesArray,
    entities = {}
  }
  if zonesArray == nil then
    mercs.zones = {
      { name = 'Pacifica'},
      { name = 'Watson' },
      { name = 'WestBrook'},
      { name = 'Santo Domingo'},
      { name = 'Heywood' },
      { name = 'Downtown' },
      { name = 'Badlands' },
    }
  end
  for gidx = 1, gangsLen do
    local gName = Gangs.data[gidx].name
    if gName == "generic" then
        print("found generic gang")
        for unitIdx = 1, #Gangs.data[gidx].entities do
          if string.match(Gangs.data[gidx].entities[unitIdx].entity_name, stringMatchFilter) then
            print("entity match found")
            table.insert(mercs.entities, Gangs.data[gidx].entities[unitIdx])
          end
        end
    end
  end
  return mercs
end

function Gangs.GenerateGangWithRandomName(zonesArray)
  -- add goons everywhere
  local randomGroups = {"_goon", "_merc"}
  local adjLen = #adjectives
  local nounLen = #nouns
  local prefixSuffix = math.random(1,100)
  local gangName = ''
  if prefixSuffix > 50 then
    print("Gangs: GenerateGangWithRandomName: Using prefix")
    gangName = adjectives[math.random(1, adjLen)] .. " " .. nouns[math.random(1, nounLen)]
    print("Gang name:" .. gangName)
  else
    print("Gangs: GenerateGangWithRandomName: Using suffix")
    gangName = nouns[math.random(1, nounLen)] .. " " .. adjectives[math.random(1, adjLen)]
    print("Gang name:" .. gangName)
  end
  local gang = Gangs.CreateGang(gangName, randomGroups[math.random(1, 2)], zonesArray)
  print("After CreateGang...")
  print(gang)
  table.insert(Gangs.data, gang)
  return gang
end

function Gangs.GetRandomGang(blacklist)
  if not blacklist then
    blacklist = {}
  end
  local gang = Gangs.data[math.random(#(Gangs.data))]
  
  for i = 1, #blacklist do
    if blacklist[i] == gang.name then
      return Gangs.GetRandomGang(blacklist)
    end
  end
  return gang
end

-- Gangs.CachedCyberPunkIndex = 0
function Gangs.GetGangInfoByName(gangName)
  if Gangs['Cached' .. gangName .. 'Index'] == nil then
    Gangs['Cached' .. gangName .. 'Index'] = 0
  end
  if Gangs['Cached' .. gangName .. 'Index'] ~= 0 then
    return Gangs.data[Gangs['Cached' .. gangName .. 'Index']]
  end
  print(#(Gangs.data))
  for index, value in ipairs(Gangs.data) do
    print(index)
    print(value)
    if value.name == gangName then
      Gangs['Cached' .. gangName .. 'Index'] = index
      return value
    end
  end
end

function Gangs.CyberpunksGangInfo()
  return Gangs.GetGangInfoByName('cyberpunk')
end
function Gangs.AldecaldoGangInfo()
  return Gangs.GetGangInfoByName('aldecaldo')
end
function Gangs.MoxGangInfo()
  return Gangs.GetGangInfoByName('mox')
end

function Gangs.RandomCyberpunkInfo()
  local gang = Gangs.CyberpunksGangInfo()
  return gang.entities[math.random(#gang.entities)]
end

function Gangs.RandomAldecaldoInfo()
  local gang = Gangs.AldecaldoGangInfo()
  return gang.entities[math.random(#gang.entities)]
end

function Gangs.RandomMoxInfo()
  local gang = Gangs.MoxGangInfo()
  return gang.entities[math.random(#gang.entities)]
end

return Gangs
