using System.Security.Claims;
using LibraryApp.Data;
using LibraryApp.Models;
using LibraryApp.Models.DTOs;
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
                .Where(b => b.IsAvailable && !b.IsArchived)
                .ToListAsync();

            return Ok(books);
        }

        [HttpGet("GetArchivedBooks")]
        [AllowAnonymous]
        public async Task<IActionResult> GetArchivedBooks()
        {
            var books = await _context.Books
                .Where(b => b.IsArchived)
                .ToListAsync();

            return Ok(books);
        }

        [HttpPost("addBook")]
        public async Task<IActionResult> addBook([FromBody] BookAddRequestDTO dto)
        {
            if (dto == null || string.IsNullOrWhiteSpace(dto.Title) || string.IsNullOrWhiteSpace(dto.Author))
                return BadRequest("Title and Author are required.");

            var book = new Book
            {
                Title = dto.Title,
                Author = dto.Author,
                IsAvailable = true,
                IsArchived = false
            };

            _context.Books.Add(book);
            await _context.SaveChangesAsync();


            return Ok("Book added succefully");
        }

        [HttpPatch("ArchiveBook/{id:int}")]
        public async Task<IActionResult> ArchiveBook(int id)
        {
            var book = await _context.Books.FindAsync(id);
            if (book is null) return NotFound("Book not found.");

            book.IsArchived = true;
            await _context.SaveChangesAsync();
            return NoContent();
        }

        [HttpPatch("UnarchiveBook/{id:int}")]
        public async Task<IActionResult> UnarchiveBook(int id)
        {
            var book = await _context.Books.FindAsync(id);
            if (book is null) return NotFound("Book not found.");

            book.IsArchived = false;
            await _context.SaveChangesAsync();
            return NoContent();
        }

    }
}
