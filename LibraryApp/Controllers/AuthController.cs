using LibraryApp.Data;
using LibraryApp.Models;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Identity.Data;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using Microsoft.IdentityModel.Tokens;
using System.IdentityModel.Tokens.Jwt;
using System.Security.Claims;
using LibraryApp.Models.DTOs;
using System.Text;

namespace LibraryApp.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    public class AuthController : Controller
    {
        private readonly LibraryDbContext _context;
        private readonly IConfiguration _cfg;

        public AuthController(LibraryDbContext context, IConfiguration cfg)
        {
            _context = context;
            _cfg = cfg;
        }

        [HttpPost("Register")]
        [AllowAnonymous]
        public async Task<IActionResult> Register([FromBody] registerRequestDTO req)
        {
            if (await _context.Users.AnyAsync(u => u.Email == req.Email))
                return Conflict(new { message = "Email already in use." });

            var user = new User
            {
                Username = req.Username,
                Email = req.Email,
                Password = req.Password, // For now dont hash the password!!!!!!!!!!
            };

            _context.Users.Add(user);
            await _context.SaveChangesAsync();
            var (token, exp) = CreateJwt(user);
            return Ok(new AuthResponseDTO(token, exp, new { user.Id, user.Username, user.Email }));
        }

        private (string token, DateTime exp) CreateJwt(User user)
        {
            var jwt = _cfg.GetSection("Jwt");
            var key = new SymmetricSecurityKey(Encoding.UTF8.GetBytes(jwt["Key"]!));
            var creds = new SigningCredentials(key, SecurityAlgorithms.HmacSha256);

            var claims = new[]
            {
                new Claim(ClaimTypes.NameIdentifier, user.Id.ToString()),
                new Claim(ClaimTypes.Name, user.Username),
                new Claim(ClaimTypes.Email, user.Email),
            };

            var expires = DateTime.UtcNow.AddMinutes(int.Parse(jwt["AccessTokenMinutes"]!));

            var token = new JwtSecurityToken(
                issuer: jwt["Issuer"],
                audience: jwt["Audience"],
                claims: claims,
                expires: expires,
                signingCredentials: creds);

            return (new JwtSecurityTokenHandler().WriteToken(token), expires);
        }

        [AllowAnonymous]
        [HttpPost("login")]
        public async Task<IActionResult> Login([FromBody] LoginRequestDTO req)
        {
            var id = (req.Email ?? "").Trim().ToLowerInvariant();
            var user = await _context.Users.SingleOrDefaultAsync(u =>
                u.Email.ToLower() == id || u.Username.ToLower() == id);

            if (user == null || user.Password != (req.Password ?? ""))
                return Unauthorized(new { message = "Invalid credentials." });

            var (token, exp) = CreateJwt(user);
            return Ok(new AuthResponseDTO(token, exp, new { user.Id, user.Username, user.Email }));
        }
    }
}
