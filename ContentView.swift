import SwiftUI
import Combine


struct UserAccount: Codable, Identifiable {
    var id = UUID()
    let name: String
    let login: String
    let password: String
}

class UserDatabase: ObservableObject {
    private let dbKey = "app_saved_users_db"
    @Published var users: [UserAccount] = []
    
    init() {
        loadFromDatabase()
        if users.isEmpty {
            users.append(UserAccount(name: "Богдана", login: "bohdana", password: "123"))
            saveToDatabase()
        }
    }
    
    func register(name: String, login: String, pass: String) -> (success: Bool, message: String) {
        if users.contains(where: { $0.login.lowercased() == login.lowercased() }) {
            return (false, "Користувач із таким логіном вже існує!")
        }
        users.append(UserAccount(name: name, login: login, password: pass))
        saveToDatabase()
        return (true, "Реєстрація успішна!")
    }
    
    func authenticate(login: String, pass: String) -> UserAccount? {
        return users.first(where: { $0.login.lowercased() == login.lowercased() && $0.password == pass })
    }
    
    private func saveToDatabase() {
        if let encoded = try? JSONEncoder().encode(users) {
            UserDefaults.standard.set(encoded, forKey: dbKey)
        }
    }
    
    private func loadFromDatabase() {
        if let data = UserDefaults.standard.data(forKey: dbKey),
           let decoded = try? JSONDecoder().decode([UserAccount].self, from: data) {
            self.users = decoded
        }
    }
}

struct MovieComment: Identifiable, Equatable {
    let id = UUID()
    let author: String
    let text: String
    let time: String
}

struct ContentView: View {
    @StateObject private var database = UserDatabase()
    
    // НАВІГАЦІЯ ВНИЗУ (ТАБИ)
    @State private var selectedTab: String = "home"
    
    // Мова та вибір фільму
    @State private var currentLanguage: String = "ua"
    @State private var selectedMovie: String = "movie1"
    
    // Усі 11 фільмів
    let allMovies = [
        "movie1", "movie2", "movie3", "movie4", "movie5", "movie6",
        "movie7", "movie8", "movie9", "movie10", "movie11"
    ]
    
    @State private var currentUser: UserAccount? = nil
    @State private var showAuthModal: Bool = false
    
    // ТАЙМЕР СЕСІЇ (Контроль часу авторизації)
    @State private var sessionRemainingSeconds: Int = 300 // 5 хвилин
    @State private var isSessionActive: Bool = false
    let sessionTimer = Timer.publish(every: 1.0, on: .main, in: .common).autoconnect()
    
    @State private var newCommentText: String = ""
    @State private var commentsByMovie: [String: [MovieComment]] = [
        "movie1": [
            MovieComment(author: "Богдана", text: "Неймовірні спецефекти!", time: "14:10"),
            MovieComment(author: "Олексій", text: "Найкращий фільм 2026.", time: "14:25")
        ],
        "movie2": [
            MovieComment(author: "Глядач", text: "Саундтрек Ганса Ціммера просто до мурашок!", time: "12:00")
        ],
        "movie3": [
            MovieComment(author: "Марія", text: "Найкраща наукова фантастика.", time: "13:40")
        ],
        "movie4": [
            MovieComment(author: "Аліна", text: "Візуальний стиль та костюми — це щось нереальне!", time: "15:10")
        ],
        "movie5": [
            MovieComment(author: "Джейк", text: "Пандора неймовірно красива, дивитися тільки в 3D!", time: "11:20")
        ],
        "movie6": [
            MovieComment(author: "Роза", text: "Там точно було місце на дверях для двох! 😭", time: "16:05")
        ],
        "movie7": [
            MovieComment(author: "Мауї", text: "Пісні знову застрягли в голові на весь день! 🌊", time: "17:15")
        ],
        "movie8": [
            MovieComment(author: "Сісу", text: "Неймовірна східна атмосфера і крута бойовка 🐉", time: "18:20")
        ],
        "movie9": [
            MovieComment(author: "Містер Вовк", text: "Стильна анімація, дуже динамічно і смішно!", time: "19:00")
        ],
        "movie10": [
            MovieComment(author: "Король Джуліан", text: "I like to move it, move it! Легендарний мульт! 🐒", time: "13:10")
        ],
        "movie11": [
            MovieComment(author: "Еґо", text: "Готувати може кожен! Найдушевніший мультфільм 🧀", time: "20:30")
        ]
    ]
    
    @State private var showDetailScreen: Bool = false

    let texts: [String: [String: String]] = [
        "ua": [
            "app_title": "Lumière",
            "login_btn": "Увійти",
            "logout_btn": "Вийти",
            "session_title": "Сесія",
            
            "tab_home": "Домівка",
            "tab_search": "Пошук",
            "tab_store": "Магазин",
            "tab_library": "Бібліотека",
            
            // 1
            "movie1_title": "Одіссея",
            "movie1_genre": "Фентезі, пригоди",
            "movie1_year": "2026",
            "movie1_rating": "8.3",
            "movie1_desc": "Фільм Крістофера Нолана за епічною поемою Гомера про пригоди царя Ітаки.",
            
            // 2
            "movie2_title": "Дюна",
            "movie2_genre": "Пригоди, драма",
            "movie2_year": "2021",
            "movie2_rating": "8.5",
            "movie2_desc": "Науково-фантастичний епос Дені Вільнева про піщану пустелю планети Арракіс.",
            
            // 3
            "movie3_title": "Інтерстеллар",
            "movie3_genre": "Наукова фантастика",
            "movie3_year": "2014",
            "movie3_rating": "8.7",
            "movie3_desc": "Подорож крізь червоточину в пошуках нового дому для виживання людства.",
            
            // 4
            "movie4_title": "Барбі",
            "movie4_genre": "Комедія, фентезі",
            "movie4_year": "2023",
            "movie4_rating": "6.8",
            "movie4_desc": "Барбі та Кен вирушають із безтурботного Барбіленду в реальний світ у пошуках себе.",
            
            // 5
            "movie5_title": "Аватар",
            "movie5_genre": "Фантастика, бойовик",
            "movie5_year": "2009",
            "movie5_rating": "7.9",
            "movie5_desc": "Джейк Саллі потрапляє на планету Пандора та стає на захист народу На'ві.",
            
            // 6
            "movie6_title": "Титанік",
            "movie6_genre": "Драма, романтика",
            "movie6_year": "1997",
            "movie6_rating": "7.9",
            "movie6_desc": "Легендарна історія кохання Джека та Рози на борту приреченого океанського лайнера.",
            
            // 7
            "movie7_title": "Ваяна 2",
            "movie7_genre": "Анімація, пригоди",
            "movie7_year": "2024",
            "movie7_rating": "7.1",
            "movie7_desc": "Ваяна вирушає у далеку небезпечну подорож океаном разом із напівбогом Мауї.",
            
            // 8
            "movie8_title": "Рая та останній дракон",
            "movie8_genre": "Фентезі, мультфільм",
            "movie8_year": "2021",
            "movie8_rating": "7.3",
            "movie8_desc": "Відважна воїтелька Рая вирушає на пошуки останнього легендарного дракона Кумандри.",
            
            // 9
            "movie9_title": "Поганці",
            "movie9_genre": "Комедія, пригоди",
            "movie9_year": "2022",
            "movie9_rating": "6.8",
            "movie9_desc": "Команда звірів-авантюристів вирішує спробувати неможливе — стати хорошими.",
            
            // 10
            "movie10_title": "Мадагаскар",
            "movie10_genre": "Комедія, сімейний",
            "movie10_year": "2005",
            "movie10_rating": "6.9",
            "movie10_desc": "Четверо друзів із зоопарку Нью-Йорка несподівано потрапляють у дикі джунглі острова.",
            
            // 11
            "movie11_title": "Рататуй",
            "movie11_genre": "Анімація, комедія",
            "movie11_year": "2007",
            "movie11_rating": "8.1",
            "movie11_desc": "Пацюк Ремі мріє стати шеф-кухарем найкращого вишуканого ресторану Парижа.",
            
            "input_placeholder": "Напишіть коментар...",
            "btn_new_window": "Усі відгуки",
            "btn_share": "Поділитися",
            "detail_header": "Стрічка відгуків до фільму",
            "detail_close": "Закрити",
            "no_comments": "Ще немає відгуків. Будьте першим!"
        ],
        "en": [
            "app_title": "Lumière",
            "login_btn": "Sign In",
            "logout_btn": "Log Out",
            "session_title": "Session",
            
            "tab_home": "Home",
            "tab_search": "Search",
            "tab_store": "Store",
            "tab_library": "Library",
            
            "movie1_title": "Odyssey",
            "movie1_genre": "Fantasy, adventure",
            "movie1_year": "2026",
            "movie1_rating": "8.3",
            "movie1_desc": "Christopher Nolan's adaptation of Homer's epic tale of Odysseus.",
            
            "movie2_title": "Dune",
            "movie2_genre": "Adventure, drama",
            "movie2_year": "2021",
            "movie2_rating": "8.5",
            "movie2_desc": "Denis Villeneuve's sci-fi masterpiece about the desert planet Arrakis.",
            
            "movie3_title": "Interstellar",
            "movie3_genre": "Sci-Fi, drama",
            "movie3_year": "2014",
            "movie3_rating": "8.7",
            "movie3_desc": "Wormhole interstellar expedition to secure humanity's survival.",
            
            "movie4_title": "Barbie",
            "movie4_genre": "Comedy, fantasy",
            "movie4_year": "2023",
            "movie4_rating": "6.8",
            "movie4_desc": "Barbie and Ken leave Barbie Land on a voyage of discovery in the human world.",
            
            "movie5_title": "Avatar",
            "movie5_genre": "Sci-Fi, action",
            "movie5_year": "2009",
            "movie5_rating": "7.9",
            "movie5_desc": "Jake Sully explores Pandora and leads the Na'vi in an epic battle for survival.",
            
            "movie6_title": "Titanic",
            "movie6_genre": "Drama, romance",
            "movie6_year": "1997",
            "movie6_rating": "7.9",
            "movie6_desc": "A young couple from different social classes fall in love aboard the ill-fated ship.",
            
            "movie7_title": "Moana 2",
            "movie7_genre": "Animation, adventure",
            "movie7_year": "2024",
            "movie7_rating": "7.1",
            "movie7_desc": "Moana and Maui journey to the far seas of Oceania on a dangerous voyage.",
            
            "movie8_title": "Raya and the Last Dragon",
            "movie8_genre": "Fantasy, animation",
            "movie8_year": "2021",
            "movie8_rating": "7.3",
            "movie8_desc": "A lone warrior tracks down the legendary last dragon to restore peace to Kumandra.",
            
            "movie9_title": "The Bad Guys",
            "movie9_genre": "Comedy, animation",
            "movie9_year": "2022",
            "movie9_rating": "6.8",
            "movie9_desc": "A criminal crew of animal outlaws attempts to become good model citizens.",
            
            "movie10_title": "Madagascar",
            "movie10_genre": "Comedy, family",
            "movie10_year": "2005",
            "movie10_rating": "6.9",
            "movie10_desc": "A group of zoo animals unexpectedly shipwreck on the wild island of Madagascar.",
            
            "movie11_title": "Ratatouille",
            "movie11_genre": "Animation, comedy",
            "movie11_year": "2007",
            "movie11_rating": "8.1",
            "movie11_desc": "A rat with a gifted sense of taste dreams of becoming a chef in a Paris restaurant.",
            
            "input_placeholder": "Write a comment...",
            "btn_new_window": "All Reviews",
            "btn_share": "Share",
            "detail_header": "Movie Review Feed",
            "detail_close": "Close",
            "no_comments": "No reviews yet. Be the first!"
        ]
    ]

    var shareText: String {
        let title = texts[currentLanguage]?["\(selectedMovie)_title"] ?? ""
        let currentComments = commentsByMovie[selectedMovie] ?? []
        let lastComment = currentComments.last?.text ?? "Рекомендую переглянути!"
        return "🎬 Фільм: \(title)\n💬 Мій відгук: \(lastComment)\nСтворено в Lumière ✨"
    }

    var formattedSessionTime: String {
        let minutes = sessionRemainingSeconds / 60
        let seconds = sessionRemainingSeconds % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }

    var body: some View {
        ScrollViewReader { scrollProxy in
            ZStack(alignment: .bottom) {
                
               
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 0) {
                        
                      
                        HStack(alignment: .center, spacing: 10) {
                            HStack(spacing: 6) {
                                Image(systemName: "film.fill")
                                    .foregroundColor(.yellow)
                                Text(texts[currentLanguage]?["app_title"] ?? "")
                                    .font(.system(size: 20, weight: .bold, design: .rounded))
                                    .foregroundColor(.white)
                            }

                            Spacer()

                         
                            if let user = currentUser {
                                HStack(spacing: 6) {
                                    Image(systemName: "person.crop.circle.fill")
                                        .foregroundColor(.yellow)
                                    Text(user.name)
                                        .font(.system(size: 12, weight: .bold))
                                        .foregroundColor(.white)
                                    
                                    // ТАЙМЕР АКТИВНОЇ СЕСІЇ ⏳
                                    Text("⏳ \(formattedSessionTime)")
                                        .font(.system(size: 11, weight: .heavy, design: .monospaced))
                                        .foregroundColor(sessionRemainingSeconds < 60 ? .red : .yellow)

                                    // Кнопка виходу
                                    Button(action: logout) {
                                        Image(systemName: "rectangle.portrait.and.arrow.right")
                                            .font(.caption)
                                            .foregroundColor(.white.opacity(0.8))
                                    }
                                }
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .background(.ultraThinMaterial)
                                .clipShape(Capsule())
                                .overlay(Capsule().stroke(Color.yellow.opacity(0.4), lineWidth: 1))
                            } else {
                                // КНОПКА «УВІЙТИ»
                                Button(action: { showAuthModal = true }) {
                                    HStack(spacing: 5) {
                                        Image(systemName: "person.circle")
                                        Text(texts[currentLanguage]?["login_btn"] ?? "")
                                            .font(.system(size: 13, weight: .bold, design: .rounded))
                                    }
                                    .foregroundColor(.black)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(Color.yellow)
                                    .clipShape(Capsule())
                                }
                            }

                            // МЕНЮ МОВИ
                            Menu {
                                Button(action: { withAnimation { currentLanguage = "ua" } }) {
                                    Label("Українська", systemImage: currentLanguage == "ua" ? "checkmark" : "")
                                }
                                Button(action: { withAnimation { currentLanguage = "en" } }) {
                                    Label("English", systemImage: currentLanguage == "en" ? "checkmark" : "")
                                }
                            } label: {
                                Text(currentLanguage == "ua" ? "🇺🇦" : "🇬🇧")
                                    .font(.system(size: 15))
                                    .padding(7)
                                    .background(.ultraThinMaterial)
                                    .clipShape(Circle())
                            }
                        }
                        .padding(.horizontal, 18)
                        .padding(.top, 10)

                        // 2. КАРУСЕЛЬ ПОСТЕРІВ (COVER FLOW З 11 ФІЛЬМАМИ)
                        VStack(spacing: 12) {
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 14) {
                                    ForEach(allMovies, id: \.self) { movieKey in
                                        let isSelected = (selectedMovie == movieKey)
                                        
                                        Button(action: {
                                            switchTo(movieKey)
                                            withAnimation(.spring(response: 0.4)) {
                                                scrollProxy.scrollTo(movieKey, anchor: .center)
                                            }
                                        }) {
                                            Image(movieKey)
                                                .resizable()
                                                .scaledToFill()
                                                .frame(
                                                    width: isSelected ? 180 : 125,
                                                    height: isSelected ? 260 : 190
                                                )
                                                .clipShape(RoundedRectangle(cornerRadius: 18))
                                                .overlay(
                                                    RoundedRectangle(cornerRadius: 18)
                                                        .stroke(
                                                            isSelected ? Color.yellow : Color.white.opacity(0.25),
                                                            lineWidth: isSelected ? 2.5 : 1
                                                        )
                                                )
                                                .opacity(isSelected ? 1.0 : 0.5)
                                                .scaleEffect(isSelected ? 1.0 : 0.92)
                                                .shadow(
                                                    color: isSelected ? Color.black.opacity(0.7) : Color.clear,
                                                    radius: 18, x: 0, y: 10
                                                )
                                                .animation(.spring(response: 0.35, dampingFraction: 0.75), value: selectedMovie)
                                        }
                                        .id(movieKey)
                                    }
                                }
                                .padding(.horizontal, 40)
                                .padding(.vertical, 10)
                            }

                           
                            HStack(spacing: 4) {
                                ForEach(allMovies, id: \.self) { item in
                                    Capsule()
                                        .fill(selectedMovie == item ? Color.yellow : Color.white.opacity(0.35))
                                        .frame(width: selectedMovie == item ? 16 : 5, height: 5)
                                        .animation(.spring(response: 0.35), value: selectedMovie)
                                }
                            }
                        }
                        .padding(.vertical, 8)

                      
                        VStack(spacing: 14) {
                            
                            Text(texts[currentLanguage]?["\(selectedMovie)_title"] ?? "")
                                .font(.system(size: 20, weight: .bold, design: .rounded))
                                .foregroundColor(.white)

                            // Бейджі (Рейтинг, Рік, Жанр)
                            HStack(spacing: 8) {
                                HStack(spacing: 4) {
                                    Image(systemName: "star.fill")
                                        .foregroundColor(.yellow)
                                        .font(.system(size: 11))
                                    Text(texts[currentLanguage]?["\(selectedMovie)_rating"] ?? "")
                                        .font(.system(size: 12, weight: .bold, design: .rounded))
                                        .foregroundColor(.white)
                                }
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.black.opacity(0.4))
                                .cornerRadius(8)

                                Text(texts[currentLanguage]?["\(selectedMovie)_year"] ?? "")
                                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                                    .foregroundColor(.white.opacity(0.85))
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(Color.white.opacity(0.15))
                                    .cornerRadius(8)

                                Text(texts[currentLanguage]?["\(selectedMovie)_genre"] ?? "")
                                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                                    .foregroundColor(.white.opacity(0.85))
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(Color.white.opacity(0.15))
                                    .cornerRadius(8)
                            }

                            Text(texts[currentLanguage]?["\(selectedMovie)_desc"] ?? "")
                                .font(.system(size: 12, weight: .regular))
                                .foregroundColor(.white.opacity(0.8))
                                .multilineTextAlignment(.center)
                                .lineLimit(2)
                                .padding(.horizontal, 8)

                            Divider().background(Color.white.opacity(0.2))

                            HStack {
                                Image(systemName: "text.bubble.fill")
                                    .foregroundColor(.yellow)
                                TextField(
                                    "",
                                    text: $newCommentText,
                                    prompt: Text(texts[currentLanguage]?["input_placeholder"] ?? "").foregroundColor(.white.opacity(0.5))
                                )
                                .foregroundColor(.white)
                                .tint(.yellow)
                                
                                Button(action: addComment) {
                                    Image(systemName: "arrow.up.circle.fill")
                                        .font(.title2)
                                        .foregroundColor(newCommentText.isEmpty ? .gray : .yellow)
                                }
                                .disabled(newCommentText.trimmingCharacters(in: .whitespaces).isEmpty)
                            }
                            .padding(12)
                            .background(Color.white.opacity(0.12))
                            .cornerRadius(14)
                            .overlay(
                                RoundedRectangle(cornerRadius: 14)
                                    .stroke(Color.white.opacity(0.2), lineWidth: 1)
                            )

                    
                            VStack(alignment: .leading, spacing: 8) {
                                let list = commentsByMovie[selectedMovie] ?? []
                                if list.isEmpty {
                                    Text(texts[currentLanguage]?["no_comments"] ?? "")
                                        .font(.caption)
                                        .foregroundColor(.white.opacity(0.6))
                                        .padding(.vertical, 4)
                                } else {
                                    ForEach(list.suffix(2)) { comment in
                                        HStack(alignment: .top, spacing: 8) {
                                            Image(systemName: "quote.opening")
                                                .font(.caption2)
                                                .foregroundColor(.yellow)
                                            VStack(alignment: .leading, spacing: 2) {
                                                Text(comment.author)
                                                    .font(.system(size: 11, weight: .bold))
                                                    .foregroundColor(.yellow.opacity(0.9))
                                                Text(comment.text)
                                                    .font(.system(size: 13))
                                                    .foregroundColor(.white)
                                                    .lineLimit(2)
                                            }
                                            Spacer()
                                            Text(comment.time)
                                                .font(.system(size: 10))
                                                .foregroundColor(.white.opacity(0.4))
                                            
                                            Button(action: { deleteComment(id: comment.id) }) {
                                                Image(systemName: "trash")
                                                    .font(.caption2)
                                                    .foregroundColor(.red.opacity(0.75))
                                                    .padding(4)
                                            }
                                        }
                                        .padding(10)
                                        .background(Color.black.opacity(0.35))
                                        .cornerRadius(10)
                                    }
                                }
                            }

                     
                            HStack(spacing: 10) {
                                Button(action: { showDetailScreen = true }) {
                                    HStack(spacing: 6) {
                                        Image(systemName: "rectangle.stack.fill")
                                        Text(texts[currentLanguage]?["btn_new_window"] ?? "")
                                            .font(.system(size: 12, weight: .bold, design: .rounded))
                                    }
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 13)
                                    .background(Color.black)
                                    .cornerRadius(14)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 14)
                                            .stroke(Color.white.opacity(0.25), lineWidth: 1)
                                    )
                                }

                                ShareLink(
                                    item: shareText,
                                    preview: SharePreview("Lumière Cinema", image: Image(selectedMovie))
                                ) {
                                    HStack(spacing: 6) {
                                        Image(systemName: "paperplane.fill")
                                        Text(texts[currentLanguage]?["btn_share"] ?? "")
                                            .font(.system(size: 12, weight: .bold, design: .rounded))
                                    }
                                    .foregroundColor(.black)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 13)
                                    .background(Color.yellow)
                                    .cornerRadius(14)
                                }
                            }
                        }
                        .padding(20)
                        .background(.ultraThinMaterial)
                        .cornerRadius(28)
                        .overlay(
                            RoundedRectangle(cornerRadius: 28)
                                .stroke(Color.white.opacity(0.2), lineWidth: 1)
                        )
                        .padding(.horizontal, 16)
                        .padding(.bottom, 95)
                    }
                }

            
                HStack(spacing: 0) {
                    TabBarButton(
                        icon: "house.fill",
                        title: texts[currentLanguage]?["tab_home"] ?? "Домівка",
                        isSelected: selectedTab == "home"
                    ) {
                        withAnimation(.spring(response: 0.3)) { selectedTab = "home" }
                    }

                    TabBarButton(
                        icon: "magnifyingglass",
                        title: texts[currentLanguage]?["tab_search"] ?? "Пошук",
                        isSelected: selectedTab == "search"
                    ) {
                        withAnimation(.spring(response: 0.3)) { selectedTab = "search" }
                    }

                    TabBarButton(
                        icon: "bag.fill",
                        title: texts[currentLanguage]?["tab_store"] ?? "Магазин",
                        isSelected: selectedTab == "store"
                    ) {
                        withAnimation(.spring(response: 0.3)) { selectedTab = "store" }
                    }

                    TabBarButton(
                        icon: "bookmark.fill",
                        title: texts[currentLanguage]?["tab_library"] ?? "Бібліотека",
                        isSelected: selectedTab == "library"
                    ) {
                        withAnimation(.spring(response: 0.3)) { selectedTab = "library" }
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(.ultraThinMaterial)
                .clipShape(Capsule())
                .overlay(
                    Capsule().stroke(Color.white.opacity(0.25), lineWidth: 1)
                )
                .shadow(color: Color.black.opacity(0.5), radius: 18, x: 0, y: 8)
                .padding(.horizontal, 24)
                .padding(.bottom, 6)
            }
        }
        .background(
            ZStack {
                Color.black

                Image(selectedMovie)
                    .resizable()
                    .scaledToFill()
                    .blur(radius: 50)
                    .scaleEffect(1.2)
                    .animation(.easeInOut(duration: 0.5), value: selectedMovie)

                LinearGradient(
                    colors: [
                        Color.black.opacity(0.45),
                        Color.black.opacity(0.25),
                        Color.black.opacity(0.7)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            }
            .ignoresSafeArea()
        )

        .onReceive(sessionTimer) { _ in
            guard isSessionActive else { return }
            if sessionRemainingSeconds > 0 {
                sessionRemainingSeconds -= 1
            } else {
                logout()
            }
        }

        .sheet(isPresented: $showAuthModal) {
            AuthView(database: database) { loggedInUser in
                self.currentUser = loggedInUser
                self.sessionRemainingSeconds = 300 // 5 хвилин
                self.isSessionActive = true
                self.showAuthModal = false
            }
        }

        .sheet(isPresented: $showDetailScreen) {
            ReviewFeedView(
                movieName: texts[currentLanguage]?["\(selectedMovie)_title"] ?? "",
                moviePoster: selectedMovie,
                comments: commentsByMovie[selectedMovie] ?? [],
                headerTitle: texts[currentLanguage]?["detail_header"] ?? "",
                closeTitle: texts[currentLanguage]?["detail_close"] ?? "",
                noCommentsText: texts[currentLanguage]?["no_comments"] ?? "",
                onDelete: { id in
                    deleteComment(id: id)
                }
            )
        }
    }

    private func logout() {
        withAnimation {
            currentUser = nil
            isSessionActive = false
            sessionRemainingSeconds = 0
        }
    }

    private func addComment() {
        let trimmed = newCommentText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        let currentTime = formatter.string(from: Date())
        
        let authorName = currentUser?.name ?? "Гість"
        let newComment = MovieComment(author: authorName, text: trimmed, time: currentTime)
        
        withAnimation(.spring()) {
            commentsByMovie[selectedMovie]?.append(newComment)
            newCommentText = ""
        }
    }

    private func deleteComment(id: UUID) {
        withAnimation(.easeInOut(duration: 0.3)) {
            commentsByMovie[selectedMovie]?.removeAll { $0.id == id }
        }
    }

    private func switchTo(_ movie: String) {
        withAnimation(.spring(response: 0.45, dampingFraction: 0.8)) {
            selectedMovie = movie
        }
    }
}

struct TabBarButton: View {
    let icon: String
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: isSelected ? 18 : 16, weight: isSelected ? .bold : .medium))
                    .foregroundColor(isSelected ? .yellow : .white.opacity(0.5))
                    .frame(height: 22)

                Text(title)
                    .font(.system(size: 10, weight: isSelected ? .bold : .medium, design: .rounded))
                    .foregroundColor(isSelected ? .yellow : .white.opacity(0.5))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 4)
        }
    }
}


struct AuthView: View {
    @ObservedObject var database: UserDatabase
    var onLoginSuccess: (UserAccount) -> Void
    
    @Environment(\.dismiss) var dismiss
    @State private var isRegisterMode: Bool = false
    
    @State private var nameInput: String = ""
    @State private var loginInput: String = ""
    @State private var passwordInput: String = ""
    @State private var errorMessage: String = ""

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VStack(spacing: 22) {
                HStack {
                    Text(isRegisterMode ? "Створити акаунт" : "Авторизація")
                        .font(.system(size: 22, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                    Spacer()
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title2)
                            .foregroundColor(.white.opacity(0.6))
                    }
                }
                .padding(.top, 20)

                // СТИЛЬНИЙ ПЕРЕМИКАЧ
                HStack(spacing: 8) {
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.25)) {
                            isRegisterMode = false
                            errorMessage = ""
                        }
                    }) {
                        Text("Вхід")
                            .font(.system(size: 15, weight: .bold, design: .rounded))
                            .foregroundColor(!isRegisterMode ? .black : .white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 11)
                            .background(!isRegisterMode ? Color.yellow : Color.white.opacity(0.12))
                            .cornerRadius(12)
                    }

                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.25)) {
                            isRegisterMode = true
                            errorMessage = ""
                        }
                    }) {
                        Text("Новий акаунт")
                            .font(.system(size: 15, weight: .bold, design: .rounded))
                            .foregroundColor(isRegisterMode ? .black : .white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 11)
                            .background(isRegisterMode ? Color.yellow : Color.white.opacity(0.12))
                            .cornerRadius(12)
                    }
                }
                .padding(4)
                .background(Color.white.opacity(0.08))
                .cornerRadius(16)
                .padding(.bottom, 6)

                // ПОЛЯ ВВЕДЕННЯ
                VStack(spacing: 14) {
                    if isRegisterMode {
                        HStack(spacing: 12) {
                            Image(systemName: "person.fill")
                                .foregroundColor(.yellow)
                                .frame(width: 20)
                            TextField(
                                "",
                                text: $nameInput,
                                prompt: Text("Ваше ім'я").foregroundColor(.white.opacity(0.6))
                            )
                            .foregroundColor(.white)
                            .tint(.yellow)
                        }
                        .padding(14)
                        .background(Color.white.opacity(0.15))
                        .cornerRadius(14)
                        .overlay(
                            RoundedRectangle(cornerRadius: 14)
                                .stroke(Color.white.opacity(0.35), lineWidth: 1)
                        )
                    }

                    HStack(spacing: 12) {
                        Image(systemName: "at")
                            .foregroundColor(.yellow)
                            .frame(width: 20)
                        TextField(
                            "",
                            text: $loginInput,
                            prompt: Text("Логін (email / username)").foregroundColor(.white.opacity(0.6))
                        )
                        .textInputAutocapitalization(.never)
                        .foregroundColor(.white)
                        .tint(.yellow)
                    }
                    .padding(14)
                    .background(Color.white.opacity(0.15))
                    .cornerRadius(14)
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(Color.white.opacity(0.35), lineWidth: 1)
                    )

                    HStack(spacing: 12) {
                        Image(systemName: "lock.fill")
                            .foregroundColor(.yellow)
                            .frame(width: 20)
                        SecureField(
                            "",
                            text: $passwordInput,
                            prompt: Text("Пароль").foregroundColor(.white.opacity(0.6))
                        )
                        .foregroundColor(.white)
                        .tint(.yellow)
                    }
                    .padding(14)
                    .background(Color.white.opacity(0.15))
                    .cornerRadius(14)
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(Color.white.opacity(0.35), lineWidth: 1)
                    )
                }

                if !errorMessage.isEmpty {
                    Text(errorMessage)
                        .font(.caption.bold())
                        .foregroundColor(.red)
                        .multilineTextAlignment(.center)
                }

                Button(action: performAuth) {
                    Text(isRegisterMode ? "Зареєструватися" : "Увійти в акаунт")
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundColor(.black)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Color.yellow)
                        .cornerRadius(16)
                }
                .padding(.top, 10)

                Spacer()
            }
            .padding(.horizontal, 24)
        }
    }

    private func performAuth() {
        errorMessage = ""
        let login = loginInput.trimmingCharacters(in: .whitespaces)
        let pass = passwordInput.trimmingCharacters(in: .whitespaces)
        
        guard !login.isEmpty, !pass.isEmpty else {
            errorMessage = "Будь ласка, заповніть усі поля!"
            return
        }

        if isRegisterMode {
            let name = nameInput.trimmingCharacters(in: .whitespaces)
            guard !name.isEmpty else {
                errorMessage = "Вкажіть ваше ім'я!"
                return
            }
            let result = database.register(name: name, login: login, pass: pass)
            if result.success {
                if let newUser = database.authenticate(login: login, pass: pass) {
                    onLoginSuccess(newUser)
                }
            } else {
                errorMessage = result.message
            }
        } else {
            if let user = database.authenticate(login: login, pass: pass) {
                onLoginSuccess(user)
            } else {
                errorMessage = "Невірний логін або пароль!"
            }
        }
    }
}

struct ReviewFeedView: View {
    @Environment(\.dismiss) var dismiss
    let movieName: String
    let moviePoster: String
    let comments: [MovieComment]
    let headerTitle: String
    let closeTitle: String
    let noCommentsText: String
    let onDelete: (UUID) -> Void

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VStack(spacing: 16) {
                HStack {
                    Text(headerTitle)
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                    Spacer()
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title2)
                            .foregroundColor(.white.opacity(0.7))
                    }
                }
                .padding(.top, 20)

                HStack(spacing: 14) {
                    Image(moviePoster)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 70, height: 100)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.white.opacity(0.3), lineWidth: 1)
                        )

                    VStack(alignment: .leading, spacing: 4) {
                        Text(movieName)
                            .font(.title3.bold())
                            .foregroundColor(.white)
                        Text("Всього відгуків: \(comments.count)")
                            .font(.caption)
                            .foregroundColor(.yellow)
                    }
                    Spacer()
                }
                .padding(12)
                .background(Color.white.opacity(0.08))
                .cornerRadius(16)

                ScrollView {
                    VStack(spacing: 10) {
                        if comments.isEmpty {
                            Text(noCommentsText)
                                .foregroundColor(.white.opacity(0.6))
                                .padding(.top, 30)
                        } else {
                            ForEach(comments) { item in
                                HStack(alignment: .top, spacing: 10) {
                                    VStack(alignment: .leading, spacing: 6) {
                                        HStack {
                                            Image(systemName: "person.circle.fill")
                                                .foregroundColor(.yellow)
                                            Text(item.author)
                                                .font(.caption.bold())
                                                .foregroundColor(.white.opacity(0.85))
                                            Spacer()
                                            Text(item.time)
                                                .font(.caption2)
                                                .foregroundColor(.white.opacity(0.4))
                                        }

                                        Text(item.text)
                                            .font(.body)
                                            .foregroundColor(.white)
                                    }

                                    Button(action: { onDelete(item.id) }) {
                                        Image(systemName: "trash.fill")
                                            .font(.system(size: 14))
                                            .foregroundColor(.red.opacity(0.8))
                                            .padding(8)
                                    }
                                }
                                .padding(14)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(Color.white.opacity(0.1))
                                .cornerRadius(14)
                            }
                        }
                    }
                    .padding(.vertical, 8)
                }

                Button(action: { dismiss() }) {
                    Text(closeTitle)
                        .bold()
                        .foregroundColor(.black)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Color.yellow)
                        .cornerRadius(16)
                }
                .padding(.bottom, 16)
            }
            .padding(.horizontal, 20)
        }
    }
}

#Preview {
    ContentView()
}
