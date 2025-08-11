namespace LibraryApp.Models.DTOs
{
    public class AuthResponseDTO
    {
        public string AccessToken { get; init; } = default!;
        public DateTime ExpiresAtUtc { get; init; }
        public object User { get; init; } = default!;

        public AuthResponseDTO(string accessToken, DateTime expiresAtUtc, object user)
        {
            AccessToken = accessToken;
            ExpiresAtUtc = expiresAtUtc;
            User = user;
        }
    }
}
