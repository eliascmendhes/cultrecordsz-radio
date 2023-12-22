import SwiftUI
import AVKit

class RadioInfoManager: ObservableObject {
    @Published var radioInfo: RadioInfo?

    func fetchData() {
        guard let url = URL(string: "https://public.radio.co/stations/sefac315e7/status?v=1703130051008") else {
            return
        }
        
        URLSession.shared.dataTask(with: url) { data, _, error in
            if let data = data {
                do {
                    let decoder = JSONDecoder()
                    let radioInfo = try decoder.decode(RadioInfo.self, from: data)
                    DispatchQueue.main.async {
                        self.radioInfo = radioInfo
                    }
                } catch {
                    print("Error decoding JSON: \(error)")
                }
            }
        }.resume()
    }
}

struct ContentView: View {
    @StateObject private var radioInfoManager = RadioInfoManager()
    @State private var isPlaying: Bool = false
    @State private var player: AVPlayer?

    var body: some View {
        VStack(spacing: 20) {
            if let radioInfo = radioInfoManager.radioInfo {
                AsyncImage(url: URL(string: radioInfo.current_track.artwork_url_large)) { phase in
                    switch phase {
                    case .empty:
                        ProgressView()
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 200, height: 200)
                    case .failure:
                        Image(systemName: "exclamationmark.triangle")
                            .frame(width: 200, height: 200)
                    @unknown default:
                        EmptyView()
                    }
                }
                
                Text("Playing: \(radioInfo.current_track.title)")
                    .foregroundColor(Color.white)
                    .padding()
                    .font(Font.custom("VT323-Regular", size: 24))
                    .overlay(Color.red.opacity(0.4).blur(radius:5))
                    .padding(.top)
                Button(action: {
                    if isPlaying {
                        player?.pause()
                    } else {
                        playRadio()
                    }
                    isPlaying.toggle()
                }) {
                    Image(systemName: isPlaying ? "pause.circle" : "play.circle")
                        .font(.system(size: 50))
                        .foregroundColor(Color(red: 179 / 255, green: 0, blue: 0))
                        .shadow(color: Color.red.opacity(0.5), radius: 2, x: 2, y: 2)
                }
                .padding()
            } else {
                ProgressView()
            }
        }
        .onAppear {
            fetchData()
            // Fetch data periodically (every 30 seconds in this example)
            Timer.scheduledTimer(withTimeInterval: 30, repeats: true) { _ in
                radioInfoManager.fetchData()
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black)
        .edgesIgnoringSafeArea(.all)
    }

    private func fetchData() {
        radioInfoManager.fetchData()
    }

    private func playRadio() {
        guard let streamURL = URL(string: "https://streaming.radio.co/sefac315e7/listen") else {
            return
        }
        
        let playerItem = AVPlayerItem(url: streamURL)
        player = AVPlayer(playerItem: playerItem)
        player?.volume = 1.0
        player?.play()
    }
}


struct RadioInfo: Codable {
    let status: String
    let source: Source
    let current_track: CurrentTrack
    let history: [Track]
}

struct CurrentTrack: Codable {
    let title: String
    let start_time: String
    let artwork_url_large: String
}

struct Source: Codable {
    let type: String
    let collaborator: String?
    let relay: String?
}

struct Track: Codable {
    let title: String
}
