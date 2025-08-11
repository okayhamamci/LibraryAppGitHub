using System.Security.Claims;
using LibraryApp.Data;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;

namespace LibraryApp.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    public class BookController : ControllerBase
    {
        private readonly LibraryDbContext _context;
        public BookController(LibraryDbContext context) => _context = context;

        [HttpGet("GetAvailableBooks")]
        [AllowAnonymous]
        public async Task<IActionResult> GetAvailableBooks()
        {
            var books = await _context.Books
                .Where(b => b.IsAvailable)
                .ToListAsync();

            return Ok(books);
        }

    }
}
