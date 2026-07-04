import QtQuick
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import "root:/theme"

Item {
    id: emojiWrapper

    readonly property int pad: 16
    implicitWidth: 420
    implicitHeight: 310

    focus: true
    Keys.onEscapePressed: capsule.currentMode = "default"

    // Process to copy emoji to clipboard
    Process {
        id: copyProcess
    }

    function copyEmoji(emojiChar) {
        copyProcess.command = ["wl-copy", emojiChar];
        copyProcess.running = true;
        
        // Return capsule to default mode
        capsule.currentMode = "default";
    }

    // JS array of curated emojis
    readonly property var rawEmojis: [
        // Smileys
        { char: "😂", name: "risa risas feliz alegre llorar carcajada happy laugh cry joy", category: "Smileys" },
        { char: "🤣", name: "risa risas feliz alegre carcajada happy laugh rofl lol", category: "Smileys" },
        { char: "😊", name: "feliz alegre sonrisa smile happy pleased warm", category: "Smileys" },
        { char: "😍", name: "amor enamorado ojos corazon love heart eyes romantic", category: "Smileys" },
        { char: "🥰", name: "amor enamorado corazon love heart faces affectionate", category: "Smileys" },
        { char: "😘", name: "beso amor corazon kiss love heart blow kiss", category: "Smileys" },
        { char: "😜", name: "guiño lengua broma wink tongue playful", category: "Smileys" },
        { char: "🤪", name: "loco lengua broma crazy tongue goofy", category: "Smileys" },
        { char: "🤔", name: "pensar duda idea think doubt question", category: "Smileys" },
        { char: "🤨", name: "duda sospecha ceja raise eyebrow suspicious", category: "Smileys" },
        { char: "😐", name: "neutral serio cara neutral serious indifferent", category: "Smileys" },
        { char: "😒", name: "desprecio aburrido molesto annoyed bored meh", category: "Smileys" },
        { char: "🙄", name: "ojos aburrido sarcasmo roll eyes bored sarcasm", category: "Smileys" },
        { char: "😬", name: "miedo tension incomodo grimace awkward tense", category: "Smileys" },
        { char: "😌", name: "alivio paz tranquilo relieved peace calm", category: "Smileys" },
        { char: "😔", name: "triste melancolia sad pensive sorrowful", category: "Smileys" },
        { char: "😴", name: "dormir sueño cansado sleep tired zzz", category: "Smileys" },
        { char: "😎", name: "cool lentes sol genial cool sunglasses stylish", category: "Smileys" },
        { char: "🤓", name: "nerd inteligente lentes nerd smart geek", category: "Smileys" },
        { char: "🥺", name: "por favor triste ruego pleading eyes sad begging", category: "Smileys" },
        { char: "😭", name: "llorar triste dolor cry sad sobbing loud", category: "Smileys" },
        { char: "😱", name: "miedo susto sorprendido scream scared shocked", category: "Smileys" },
        { char: "😡", name: "enojo molesto rabia angry mad furious", category: "Smileys" },
        { char: "😈", name: "diablo malo travesura devil evil mischievous", category: "Smileys" },
        { char: "💩", name: "caca popo poop turd funny", category: "Smileys" },
        { char: "🤡", name: "payaso clown funny creepy", category: "Smileys" },
        { char: "👻", name: "fantasma susto ghost spooky halloween", category: "Smileys" },
        { char: "👽", name: "alien extraterrestre space alien ufo", category: "Smileys" },
        { char: "👾", name: "monstruo juego game pixel alien retro arcade", category: "Smileys" },
        { char: "🤖", name: "robot bot machine technology", category: "Smileys" },
        
        // Corazones e ideas
        { char: "❤️", name: "corazon rojo amor love red heart passion", category: "Corazones" },
        { char: "🧡", name: "corazon naranja amor love orange heart", category: "Corazones" },
        { char: "💛", name: "corazon amarillo amor love yellow heart friendship", category: "Corazones" },
        { char: "💚", name: "corazon verde amor love green heart nature", category: "Corazones" },
        { char: "💙", name: "corazon azul amor love blue heart trust", category: "Corazones" },
        { char: "💜", name: "corazon morado amor love purple heart royalty", category: "Corazones" },
        { char: "🖤", name: "corazon negro amor love black heart sorrow", category: "Corazones" },
        { char: "🤍", name: "corazon blanco amor love white heart peace", category: "Corazones" },
        { char: "💔", name: "corazon roto desamor broken heart sad split", category: "Corazones" },
        { char: "❤️‍🔥", name: "corazon fuego pasion heart on fire passion", category: "Corazones" },
        { char: "💕", name: "corazones amor dos hearts love cute", category: "Corazones" },
        { char: "💖", name: "corazon brillo amor sparkle heart glowing", category: "Corazones" },
        { char: "🔥", name: "fuego caliente flama fire hot burn lit popular", category: "Objetos" },
        { char: "✨", name: "brillos estrellas magia sparkles shine magic new", category: "Objetos" },
        { char: "🌟", name: "estrella brillo star glow shining", category: "Objetos" },
        { char: "⭐", name: "estrella star yellow classic", category: "Objetos" },
        { char: "☀️", name: "sol dia calor sun hot summer sunny", category: "Objetos" },
        { char: "☁️", name: "nube clima cloud gray overcast", category: "Objetos" },
        { char: "🌧️", name: "lluvia agua rain wet storm", category: "Objetos" },
        { char: "❄️", name: "nieve frio snow cold ice", category: "Objetos" },
        { char: "⚡", name: "rayo energia trueno lightning bolt power energy storm", category: "Objetos" },
        { char: "🌈", name: "arcoiris color rainbow bright peace LGBTQ", category: "Objetos" },
        { char: "💯", name: "cien perfecto nota 100 perfect absolute true", category: "Objetos" },
        { char: "💢", name: "enojo rabia manga anger vein pop stress", category: "Objetos" },
        { char: "💥", name: "explosion golpe boom collision spark crash", category: "Objetos" },
        { char: "💤", name: "dormir sueño zzz sleep snore tired", category: "Objetos" },

        // Gestos
        { char: "👍", name: "bien ok gusto likes up thumbs ok perfect", category: "Gestos" },
        { char: "👎", name: "mal no disgusto dislike thumbs down bad", category: "Gestos" },
        { char: "👌", name: "perfecto ok vale okay perfect hand", category: "Gestos" },
        { char: "🤌", name: "que quieres italia pinched fingers what do you want", category: "Gestos" },
        { char: "✊", name: "puño fuerza poder fist strength power", category: "Gestos" },
        { char: "👊", name: "golpe puño fist bump punch hit", category: "Gestos" },
        { char: "✌️", name: "paz victoria peace victory fingers sign", category: "Gestos" },
        { char: "🤞", name: "suerte dedos cruzados fingers crossed luck", category: "Gestos" },
        { char: "🤟", name: "te amo amor love you hand sign rock", category: "Gestos" },
        { char: "🤘", name: "rock metal cuernos sign of the horns", category: "Gestos" },
        { char: "👋", name: "hola adios mano wave hand hello goodbye greeting", category: "Gestos" },
        { char: "🙏", name: "por favor gracias rezar pray please thanks gratitude", category: "Gestos" },
        { char: "🤝", name: "trato acuerdo saludo handshake agreement trust", category: "Gestos" },
        { char: "👏", name: "aplauso felicidades clap applaud congrats", category: "Gestos" },
        { char: "🙌", name: "celebracion manos arriba raise hands celebrate", category: "Gestos" },
        { char: "💪", name: "fuerza musculo poder flex biceps strength", category: "Gestos" },

        // Comida y otros
        { char: "🍕", name: "pizza comida queso food italian junk", category: "Comida" },
        { char: "🍔", name: "hamburguesa comida carne burger fast food junk", category: "Comida" },
        { char: "🍟", name: "papas fritas comida fries fast food", category: "Comida" },
        { char: "🌮", name: "taco comida mexico taco food wrap", category: "Comida" },
        { char: "🍜", name: "ramen fideos sopa ramen noodle soup japanese", category: "Comida" },
        { char: "🍣", name: "sushi comida pescado sushi japanese seafood", category: "Comida" },
        { char: "🍎", name: "manzana fruta red apple fruit healthy", category: "Comida" },
        { char: "🍌", name: "platano banana fruta fruit yellow", category: "Comida" },
        { char: "🍉", name: "sandia fruta watermelon fruit summer", category: "Comida" },
        { char: "🍓", name: "fresa fruta strawberry fruit sweet", category: "Comida" },
        { char: "☕", name: "cafe taza bebida hot coffee tea mug", category: "Comida" },
        { char: "🍺", name: "cerveza bebida alcohol beer mug drink", category: "Comida" },
        { char: "🍻", name: "cervezas brindis cheers beer mugs alcohol", category: "Comida" },
        { char: "🍷", name: "vino bebida alcohol wine glass drink", category: "Comida" },

        // Animales
        { char: "🐶", name: "perro cachorro dog puppy pet", category: "Animales" },
        { char: "🐱", name: "gato michi cat kitten pet", category: "Animales" },
        { char: "🐭", name: "raton mouse rodent", category: "Animales" },
        { char: "🐹", name: "hamster pet rodent", category: "Animales" },
        { char: "🐰", name: "conejo rabbit bunny", category: "Animales" },
        { char: "🦊", name: "zorro fox wild animal", category: "Animales" },
        { char: "🐻", name: "oso bear wild", category: "Animales" },
        { char: "🐼", name: "panda bear cute chinese", category: "Animales" },
        { char: "🦁", name: "leon rey lion wild cat", category: "Animales" },
        { char: "🐯", name: "tigre tiger wild cat", category: "Animales" },
        { char: "🐨", name: "koala bear cute", category: "Animales" },
        { char: "🐸", name: "rana frog amphibian", category: "Animales" },
        { char: "🐵", name: "mono monkey ape", category: "Animales" },
        { char: "🐔", name: "pollo gallina chicken bird", category: "Animales" },
        { char: "🐧", name: "pinguino penguin bird polar", category: "Animales" },
        { char: "🐦", name: "pajaro bird wing flight", category: "Animales" },
        { char: "🦆", name: "pato duck bird water", category: "Animales" },
        { char: "🦅", name: "aguila eagle bird prey fly", category: "Animales" },
        { char: "🦉", name: "buho owl bird night wise", category: "Animales" },
        { char: "🐺", name: "lobo wolf wild dog pack", category: "Animales" },
        { char: "🐴", name: "caballo horse farm ride", category: "Animales" },
        { char: "🦄", name: "unicornio unicorn magic fantasy", category: "Animales" },
        { char: "🦋", name: "mariposa butterfly insect beautiful", category: "Animales" },
        { char: "🐢", name: "tortuga turtle slow reptile water", category: "Animales" },
        { char: "🐍", name: "serpiente snake reptile danger poison", category: "Animales" },
        { char: "🐙", name: "pulpo octopus ocean water tentacle", category: "Animales" },
        { char: "🐠", name: "pez tropical fish ocean aquarium", category: "Animales" },
        { char: "🐬", name: "delfin dolphin ocean smart sea", category: "Animales" },
        { char: "🐳", name: "ballena whale ocean huge", category: "Animales" },
        { char: "🦈", name: "tiburon shark ocean predator", category: "Animales" },

        // Actividades y Tecnología
        { char: "💻", name: "laptop computadora pc computer technology dev code developer", category: "Tecno" },
        { char: "🖥️", name: "monitor pantalla desktop screen", category: "Tecno" },
        { char: "📱", name: "celular telefono smartphone mobile phone call screen", category: "Tecno" },
        { char: "🎮", name: "juego control gamepad controller video game play console switch xbox playstation", category: "Tecno" },
        { char: "🎧", name: "audifonos musica headphones listen audio sound podcast", category: "Tecno" },
        { char: "🚀", name: "cohete espacio rocket space fly launch startup", category: "Tecno" },
        { char: "🛸", name: "ovni ufo space alien spaceship", category: "Tecno" },
        { char: "💡", name: "foco luz idea bulb light energy smart", category: "Tecno" },
        { char: "🔑", name: "llave key password security open lock", category: "Tecno" },
        { char: "🔒", name: "candado lock closed secure privacy", category: "Tecno" },
        { char: "🎨", name: "pintura arte palette art paint draw creative", category: "Tecno" },
        { char: "🎬", name: "cine pelicula clapperboard movie film show video", category: "Tecno" },
        { char: "🎤", name: "microfono cantar microphone karaoke sing podcast", category: "Tecno" },
        { char: "🎹", name: "piano teclado music keyboard instrument", category: "Tecno" },
        { char: "⚽", name: "futbol balon soccer ball sport play game", category: "Tecno" },
        { char: "🏆", name: "trofeo copa win trophy champion prize gold", category: "Tecno" }
    ]

    ListModel {
        id: emojiModel
    }

    function updateFilter(query) {
        emojiModel.clear();
        let q = query.trim().toLowerCase();
        
        for (let i = 0; i < rawEmojis.length; i++) {
            let emo = rawEmojis[i];
            if (q === "" || emo.name.indexOf(q) !== -1 || emo.category.toLowerCase().indexOf(q) !== -1) {
                emojiModel.append(emo);
            }
        }
        
        // Reset selection index
        if (emojiModel.count > 0) {
            gridView.currentIndex = 0;
        } else {
            gridView.currentIndex = -1;
        }
    }

    Component.onCompleted: {
        updateFilter("");
        searchInput.forceActiveFocus();
    }

    Column {
        anchors.fill: parent
        anchors.margins: pad
        spacing: 8

        // ── Header ──────────────────────────────────────────────────────────
        Item {
            width: parent.width
            height: 24

            Row {
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                spacing: 8

                Text {
                    text: "\uf118" // Smile icon
                    font.family: Theme.fontFamily
                    font.pixelSize: 14
                    color: Theme.accent
                    anchors.verticalCenter: parent.verticalCenter
                }
                Text {
                    text: Theme.t.emoji_picker ?? "Emoji Picker"
                    font.family: Theme.fontFamily
                    font.pixelSize: 12
                    font.bold: true
                    color: Theme.fg
                    anchors.verticalCenter: parent.verticalCenter
                }
            }
        }

        // Separator
        Rectangle {
            width: parent.width
            height: 1
            color: Qt.rgba(Theme.fg.r, Theme.fg.g, Theme.fg.b, 0.08)
        }

        // ── Search Input ────────────────────────────────────────────────────
        Rectangle {
            width: parent.width
            height: 32
            radius: 8
            color: Qt.rgba(Theme.bgAlt.r, Theme.bgAlt.g, Theme.bgAlt.b, 0.4)
            border.width: 1
            border.color: searchInput.activeFocus ? Theme.accent : Qt.rgba(Theme.fg.r, Theme.fg.g, Theme.fg.b, 0.08)

            Behavior on border.color { ColorAnimation { duration: 120 } }

            Row {
                anchors.fill: parent
                anchors.leftMargin: 12
                anchors.rightMargin: 12
                spacing: 8

                Text {
                    text: "\uf002" // Search icon
                    font.family: Theme.fontFamily
                    font.pixelSize: 11
                    color: Theme.fgMuted
                    anchors.verticalCenter: parent.verticalCenter
                }

                TextInput {
                    id: searchInput
                    width: parent.width - 40
                    color: Theme.fg
                    font.family: Theme.fontFamily
                    font.pixelSize: 11
                    selectByMouse: true
                    anchors.verticalCenter: parent.verticalCenter

                    Text {
                        text: Theme.t.emoji_search ?? "Buscar emoji..."
                        font.family: Theme.fontFamily
                        font.pixelSize: 11
                        color: Theme.fgMuted
                        visible: searchInput.text === ""
                        anchors.verticalCenter: parent.verticalCenter
                    }

                    onTextChanged: updateFilter(text)

                    onAccepted: {
                        if (gridView.currentIndex >= 0 && gridView.currentIndex < emojiModel.count) {
                            copyEmoji(emojiModel.get(gridView.currentIndex).char);
                        }
                    }

                    // Key navigation intercepts
                    Keys.onPressed: event => {
                        let cols = 8; // Number of columns in GridView
                        if (event.key === Qt.Key_Down) {
                            if (gridView.currentIndex + cols < emojiModel.count) {
                                gridView.currentIndex += cols;
                            }
                            event.accepted = true;
                        } else if (event.key === Qt.Key_Up) {
                            if (gridView.currentIndex - cols >= 0) {
                                gridView.currentIndex -= cols;
                            }
                            event.accepted = true;
                        } else if (event.key === Qt.Key_Right) {
                            if (gridView.currentIndex + 1 < emojiModel.count) {
                                gridView.currentIndex += 1;
                            }
                            event.accepted = true;
                        } else if (event.key === Qt.Key_Left) {
                            if (gridView.currentIndex - 1 >= 0) {
                                gridView.currentIndex -= 1;
                            }
                            event.accepted = true;
                        }
                    }
                }
            }
        }

        // ── Grid View Area ──────────────────────────────────────────────────
        Item {
            width: parent.width
            height: 200

            GridView {
                id: gridView
                anchors.fill: parent
                model: emojiModel
                clip: true
                cellWidth: 48
                cellHeight: 48
                boundsBehavior: Flickable.StopAtBounds

                delegate: Rectangle {
                    width: 42
                    height: 42
                    radius: 8
                    color: {
                        if (gridView.currentIndex === index) {
                            return Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.18);
                        }
                        return mouseArea.containsMouse ? Qt.rgba(Theme.fg.r, Theme.fg.g, Theme.fg.b, 0.06) : "transparent";
                    }
                    border.width: gridView.currentIndex === index ? 1 : 0
                    border.color: Theme.accent

                    Behavior on color { ColorAnimation { duration: 100 } }

                    Text {
                        text: model.char
                        font.pixelSize: 22
                        anchors.centerIn: parent
                    }

                    MouseArea {
                        id: mouseArea
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            copyEmoji(model.char);
                        }
                        onEntered: {
                            gridView.currentIndex = index;
                        }
                    }
                }
            }

            // Zero results placeholder
            Text {
                visible: emojiModel.count === 0
                text: "No se encontraron emojis"
                font.family: Theme.fontFamily
                font.pixelSize: 11
                color: Theme.fgMuted
                anchors.centerIn: parent
            }
        }
    }
}
