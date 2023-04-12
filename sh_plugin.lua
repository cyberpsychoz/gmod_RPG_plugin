-- Создаем плагин с именем "attributes"
PLUGIN.name = "RPG System"
PLUGIN.author = "Крыжовник"
PLUGIN.description = "Adds a system of attributes that can be rolled and affect various character stats."

-- Создаем таблицу с константами для характеристик
local STRENGTH = 1 -- Сила влияет на урон в ближнем бою и грузоподъемность
local AGILITY = 2 -- Ловкость влияет на скорость бега и шанс уклонения
local ENDURANCE = 3 -- Выносливость влияет на запас здоровья и скорость восстановления
local INTELLIGENCE = 4 -- Интеллект влияет на урон в дальнем бою и шанс критического попадания
local CHARISMA = 5 -- Харизма влияет на цены в магазинах и отношение NPC

-- Создаем таблицу с данными для характеристик
PLUGIN.attributes = {
    [STRENGTH] = {
        name = "Сила",
        description = "Определяет вашу физическую силу и выносливость.",
        icon = "path/to/strength/icon.png",
        color = Color(255, 0, 0),
        min = 1,
        max = 10,
        default = 5,
    },
    [AGILITY] = {
        name = "Ловкость",
        description = "Определяет вашу скорость и реакцию.",
        icon = "path/to/agility/icon.png",
        color = Color(0, 255, 0),
        min = 1,
        max = 10,
        default = 5,
    },
    [ENDURANCE] = {
        name = "Выносливость",
        description = "Определяет ваш запас здоровья и сопротивляемость к урону.",
        icon = "path/to/endurance/icon.png",
        color = Color(0, 0, 255),
        min = 1,
        max = 10,
        default = 5,
    },
    [INTELLIGENCE] = {
        name = "Интеллект",
        description = "Определяет вашу способность к обучению и анализу.",
        icon = "path/to/intelligence/icon.png",
        color = Color(255, 255, 0),
        min = 1,
        max = 10,
        default = 5,
    },
    [CHARISMA] = {
        name = "Харизма",
        description = "Определяет ваше обаяние и убедительность.",
        icon = "path/to/charisma/icon.png",
        color = Color(255, 0, 255),
        min = 1,
        max = 10,
        default = 5,
    },
}

-- Создаем функцию для получения значения характеристики по ее ID
function PLUGIN:GetAttribute(id)
    return self.attributes[id]
end

-- Создаем функцию для получения значения характеристики по ее имени
function PLUGIN:GetAttributeByName(name)
    for id, data in pairs(self.attributes) do
        if data.name == name then
            return data
        end
    end
end

-- Создаем функцию для получения значения характеристики персонажа по ее ID
function PLUGIN:GetCharacterAttribute(character, id)
    return character:GetData("attr_" .. id, self:GetAttribute(id).default)
end

-- Создаем функцию для установки значения характеристики персонажа по ее ID
function PLUGIN:SetCharacterAttribute(character, id, value)
    character:SetData("attr_" .. id, value)
end

-- Создаем функцию для изменения значения характеристики персонажа по ее ID
function PLUGIN:ModifyCharacterAttribute(character, id, amount)
    local value = self:GetCharacterAttribute(character, id)
    local data = self:GetAttribute(id)
    value = math.Clamp(value + amount, data.min, data.max)
    self:SetCharacterAttribute(character, id, value)
end

-- Создаем функцию для проверки, есть ли у персонажа характеристика по ее ID
function PLUGIN:HasCharacterAttribute(character, id)
    return self:GetCharacterAttribute(character, id) > 0
end

-- Создаем функцию для генерации случайного числа от 1 до 100 с учетом значения характеристики персонажа по ее ID
function PLUGIN:RollCharacterAttribute(character, id)
    local value = self:GetCharacterAttribute(character, id)
    local min = 1 + value * 2 -- минимальное значение ролла увеличивается на 2 за каждую единицу характеристики
    local max = 100 - value * 2 -- максимальное значение ролла уменьшается на 2 за каждую единицу характеристики
    return math.random(min, max) -- возвращаем случайное число в диапазоне от min до max
end

-- Создаем функцию для обработки команды /roll
ix.command.Add("Roll", {
    description = "Бросает кубик от 1 до 100 с учетом одной из характеристик.",
    arguments = {
        ix.type.text -- аргумент - имя характеристики
    },
    OnRun = function(self, client, attribute) -- функция выполнения команды
        local character = client:GetCharacter() -- получаем персонажа игрока
        local data = PLUGIN:GetAttributeByName(attribute) -- получаем данные характеристики по ее имени
        if data then -- если данные существуют
            local id = data.id -- получаем ID характеристики
            local value = PLUGIN:GetCharacterAttribute(character, id) -- получаем значение характеристики персонажа
            local result = PLUGIN:RollCharacterAttribute(character, id) -- получаем результат ролла с учетом характеристики
            ix.chat.Send(client, "roll", result .. " (" .. attribute .. ": " .. value .. ")") -- отправляем сообщение в чат с результатом ролла и значением характеристики
        else -- если данных нет
            return "Неверная характеристика." -- возвращаем ошибку
        end
    end,
})

-- Создаем функцию для обработки события создания персонажа
function PLUGIN:OnCharacterCreated(client, character)
    for id, data in pairs(self.attributes) do -- для каждой характеристики в таблице
        self:SetCharacterAttribute(character, id, data.default) -- устанавливаем значение характеристики персонажу равное значению по умолчанию
    end
end

-- Создаем функцию для обработки события загрузки персонажа
function PLUGIN:OnCharacterLoaded(character)
    for id, data in pairs(self.attributes) do -- для каждой характеристики в таблице
        if not character:GetData("attr_" .. id) then -- если у персонажа нет данных о характеристике
            self:SetCharacterAttribute(character,id, data.default) -- устанавливаем значение характеристики персонажу равное значению по умолчанию
        end
    end
end

-- Создаем функцию для обработки события получения урона персонажем
function PLUGIN:PlayerTakeDamage(client, damageInfo)
    local character = client:GetCharacter() -- получаем персонажа игрока
    if character then -- если персонаж существует
        local endurance = self:GetCharacterAttribute(character, ENDURANCE) -- получаем значение выносливости персонажа
        local damage = damageInfo:GetDamage() -- получаем значение урона
        local modifier = 1 - endurance * 0.01 -- получаем модификатор урона в зависимости от выносливости (каждая единица выносливости уменьшает урон на 1%)
        damageInfo:SetDamage(damage * modifier) -- устанавливаем новое значение урона с учетом модификатора
    end
end

-- Создаем функцию для обработки события нанесения урона персонажем
function PLUGIN:PlayerHitEntity(client, trace, entity)
    local character = client:GetCharacter() -- получаем персонажа игрока
    if character then -- если персонаж существует
        local strength = self:GetCharacterAttribute(character, STRENGTH) -- получаем значение силы персонажа
        local weapon = client:GetActiveWeapon() -- получаем активное оружие игрока
        if weapon and weapon:IsValid() and weapon:GetClass() == "weapon_fists" then -- если оружие существует и является кулаками
            local damage = weapon.Primary.Damage -- получаем значение урона оружия
            local modifier = 1 + strength * 0.01 -- получаем модификатор урона в зависимости от силы (каждая единица силы увеличивает урон на 1%)
            weapon.Primary.Damage = damage * modifier -- устанавливаем новое значение урона оружия с учетом модификатора
        end
    end
end

-- Создаем функцию для обработки события изменения скорости бега персонажа
function PLUGIN:PlayerGetRunSpeed(client, speed)
    local character = client:GetCharacter() -- получаем персонажа игрока
    if character then -- если персонаж существует
        local agility = self:GetCharacterAttribute(character, AGILITY) -- получаем значение ловкости персонажа
        local modifier = 1 + agility * 0.01 -- получаем модификатор скорости бега в зависимости от ловкости (каждая единица ловкости увеличивает скорость бега на 1%)
        return speed * modifier -- возвращаем новое значение скорости бега с учетом модификатора
    end
end

-- Создаем функцию для обработки события изменения грузоподъемности персонажа
function PLUGIN:CharacterGetInventorySize(character, width, height)
    local strength = self:GetCharacterAttribute(character, STRENGTH) -- получаем значение силы персонажа
    local modifier = 1 + strength * 0.01 -- получаем модификатор грузоподъемности в зависимости от силы (каждая единица силы увеличивает грузоподъемность на 1%)
    return width * modifier, height * modifier -- возвращаем новые значения ширины и высоты инвентаря с учетом модификатора
end

-- Создаем функцию для обработки события изменения цен в магазинах
function PLUGIN:VendorAdjustPrice(client, vendor, item, price)
    local character = client:GetCharacter() -- получаем персонажа игрока
    if character then -- если персонаж существует
        local charisma = self:GetCharacterAttribute(character, CHARISMA) -- получаем значение харизмы персонажа
        local modifier = 1 - charisma * 0.01 -- получаем модификатор цен в зависимости от харизмы (каждая единица харизмы уменьшает цены на 1%)
        return price * modifier -- возвращаем новое значение цены с учетом модификатора
    end
end

-- Создаем функцию для обработки события изменения отношения NPC к персонажу
function PLUGIN:PlayerGetDisposition(client, npc)
    local character = client:GetCharacter() -- получаем персонажа игрока
    if character then -- если персонаж существует
        local charisma = self:GetCharacterAttribute(character, CHARISMA) -- получаем значение харизмы персонажа
        local disposition = npc:Disposition(client) -- получаем текущее отношение NPC к игроку
        local modifier = charisma * 0.1 -- получаем модификатор отношения в зависимости от харизмы (каждая единица харизмы увеличивает отношение на 0.1)
        return disposition + modifier -- возвращаем новое значение отношения с учетом модификатора
    end
end

-- Создаем функцию для обработки события изменения шанса уклонения от атаки
function PLUGIN:PlayerCanDodge(client, attacker)
    local character = client:GetCharacter() -- получаем персонажа игрока
    if character then -- если персонаж существует
        local agility = self:GetCharacterAttribute(character, AGILITY) -- получаем значение ловкости персонажа
        local chance = 5 + agility * 0.5 -- получаем шанс уклонения в процентах в зависимости от ловкости (каждая единица ловкости увеличивает шанс на 0.5%)
        return math.random(100) <= chance -- возвращаем true или false в зависимости от случайного числа и шанса
    end
end

-- Создаем функцию для обработки события изменения шанса критического попадания по цели
function PLUGIN:PlayerCanCrit(client, target)
    local character = client:GetCharacter() -- получаем персонажа игрока
    if character then -- если персонаж существует
        local intelligence = self:GetCharacterAttribute(character, INTELLIGENCE) -- получаем значение интеллекта персонажа
        local chance = 5 + intelligence * 0.5 -- получаем шанс критического попадания в процентах в зависимости от интеллекта (каждая единица интеллекта увеличивает шанс на 0.5%)
        return math.random(100) <= chance -- возвращаем true или false в зависимости от случайного числа и шанса
    end
end

-- Создаем функцию для обработки события изменения урона критического попадания по цели
function PLUGIN:PlayerGetCritDamage(client, target, damage)
    local character -- получаем персонажа игрока
    if character then -- если персонаж существует
        local intelligence = self:GetCharacterAttribute(character, INTELLIGENCE) -- получаем значение интеллекта персонажа
        local modifier = 1 + intelligence * 0.01 -- получаем модификатор урона критического попадания в зависимости от интеллекта (каждая единица интеллекта увеличивает урон на 1%)
        return damage * modifier -- возвращаем новое значение урона с учетом модификатора
    end
end

-- Создаем функцию для обработки события отрисовки интерфейса
function PLUGIN:HUDPaint()
    local client = LocalPlayer() -- получаем локального игрока
    local character = client:GetCharacter() -- получаем персонажа игрока
    if character then -- если персонаж существует
        local x = ScrW() * 0.5 -- получаем координату x по центру экрана
        local y = ScrH() * 0.8 -- получаем координату y с небольшим отступом снизу
        for id, data in pairs(self.attributes) do -- для каждой характеристики в таблице
            local value = self:GetCharacterAttribute(character, id) -- получаем значение характеристики персонажа
            local color = data.color -- получаем цвет характеристики
            local icon = data.icon -- получаем иконку характеристики
            surface.SetDrawColor(color) -- устанавливаем цвет рисования
            surface.SetMaterial(Material(icon)) -- устанавливаем материал рисования
            surface.DrawTexturedRect(x - 16, y - 16, 32, 32) -- рисуем иконку характеристики по центру экрана
            draw.SimpleText(value, "DermaDefault", x + 20, y, color) -- рисуем значение характеристики справа от иконки
            y = y + 40 -- увеличиваем координату y для следующей характеристики
        end
    end
end

-- Создаем функцию для обработки события добавления пунктов меню в инвентаре персонажа
function PLUGIN:PopulateCharacterMenu(client, character, container)
    if character:IsOwner(client) then -- если персонаж принадлежит игроку
        container:Add("Attributes", function() -- добавляем пункт меню "Характеристики"
            vgui.Create("ixAttributes") -- создаем окно с характеристиками персонажа
        end)
    end
end

-- Создаем класс окна с характеристиками персонажа
local PANEL = {}

-- Создаем функцию для инициализации окна
function PANEL:Init()
    self:SetSize(ScrW() * 0.5, ScrH() * 0.5) -- устанавливаем размер окна по половине экрана
    self:Center() -- центрируем окно на экране
    self:SetTitle("Характеристики") -- устанавливаем заголовок окна

    self.list = self:Add("DScrollPanel") -- добавляем панель со скроллом в окно
    self.list:Dock(FILL) -- заполняем всё свободное пространство окна
    self.list:DockMargin(4, 4, 4, 4) -- устанавливаем отступы от краев окна

    local character = LocalPlayer():GetCharacter() -- получаем персонажа локального игрока
    if character then -- если персонаж существует
        for id, data in pairs(PLUGIN.attributes) do -- для каждой характеристики в таблице
            local value = PLUGIN:GetCharacterAttribute(character, id) -- получаем значение характеристики персонажа
            local color = data.color -- получаем цвет характеристики
            local icon = data.icon -- получаем иконку характеристики

            local panel = self.list:Add("DPanel") -- добавляем панель в панель со скроллом
            panel:Dock(TOP) -- прикрепляем панель к верху панели со скроллом
            panel:DockMargin(0, 0, 0, 4) -- устанавливаем отступы от краев панели со скроллом
            panel:SetTall(64) -- устанавливаем высоту панели
            panel:SetBackgroundColor(color) -- устанавливаем цвет фона панели

            panel.icon = panel:Add("DImage") -- добавляем изображение в панель
            panel.icon:Dock(LEFT) -- прикрепляем изображение к левому краю панели
            panel.icon:DockMargin(4, 4, 4, 4) -- устанавливаем отступы от краев панели
            panel.icon:SetWide(64) -- устанавливаем ширину изображения
            panel.icon:SetImage(icon) -- устанавливаем иконку характеристики в изображение

            panel.name = panel:Add("DLabel") -- добавляем надпись в панель
            panel.name:Dock(TOP) -- прикрепляем надпись к верху панели
            panel.name:DockMargin(72, 4, 4, 0) -- устанавливаем отступы от краев панели
            panel.name:SetText(data.name .. ": " .. value) -- устанавливаем текст надписи с именем и значением характеристики
            panel.name:SetFont("DermaLarge") -- устанавливаем шрифт надписи
            panel.name:SetTextColor(color_white) -- устанавливаем цвет текста надписи

            panel.description = panel:Add("DLabel") -- добавляем надпись в панель
            panel.description:Dock(FILL) -- заполняем всё свободное пространство панели
            panel.description:DockMargin(72, 0, 4, 4) -- устанавливаем отступы от краев панели
            panel.description:SetText(data.description) -- устанавливаем текст надписи с описанием характеристики
            panel.description:SetFont("DermaDefault") -- устанавливаем шрифт надписи
            panel.description:SetTextColor(color_white) -- устанавливаем цвет текста надписи
        end
    end

    self:MakePopup() -- делаем окно активным и видимым на экране
end

vgui.Register("ixAttributes", PANEL, "DFrame") -- регистрируем класс окна с именем "ixAttributes" и базовым классом "DFrame"
