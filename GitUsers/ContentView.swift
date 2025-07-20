import SwiftUI

struct ContentView: View {
    @State private var user: GithubUser?
    @State private var errorMessage: String?
    
    var body: some View {
        VStack {
            if let user = user {
                AsyncImage(url: URL(string: user.avatarUrl)) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .clipShape(Circle())
                } placeholder: {
                    Circle()
                        .foregroundColor(.secondary)
                }
                .frame(width: 120, height: 120)
                
                Text(user.login)
                    .bold()
                    .font(.title3)
                
                if let bio = user.bio {
                    Text(bio)
                        .padding()
                }
            } else if let errorMessage = errorMessage {
                Text(errorMessage)
                    .foregroundColor(.red)
            } else {
                ProgressView()
            }
            
            Spacer()
        }
        .padding()
        .task {
            await loadUser()
        }
    }
    
    func loadUser() async {
        do {
            user = try await getUser()
        } catch GitError.invalidURL {
            errorMessage = "Invalid URL"
        } catch GitError.invalidResponse {
            errorMessage = "Invalid response from server"
        } catch GitError.invalidData {
            errorMessage = "Invalid data received"
        } catch {
            errorMessage = "Unexpected error: \(error.localizedDescription)"
        }
    }
    
    func getUser() async throws -> GithubUser {
        let endpoint = "https://api.github.com/users/EhsanMousaviMsl"
        guard let url = URL(string: endpoint) else {
            throw GitError.invalidURL
        }
        
        let (data, response) = try await URLSession.shared.data(from: url)
        
        guard let response = response as? HTTPURLResponse, response.statusCode == 200 else {
            throw GitError.invalidResponse
        }
        
        do {
            let decoder = JSONDecoder()
            decoder.keyDecodingStrategy = .convertFromSnakeCase
            return try decoder.decode(GithubUser.self, from: data)
        } catch {
            throw GitError.invalidData
        }
    }
}

struct GithubUser: Codable {
    let login: String
    let avatarUrl: String
    let bio: String?
}  // Make bio optional

enum GitError: Error {
    case invalidURL
    case invalidResponse
    case invalidData
}

#Preview {
    ContentView()
}
