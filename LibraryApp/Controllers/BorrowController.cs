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
    [Authorize]                    
    public class BorrowController : ControllerBase
    {
        private readonly LibraryDbContext _context;
        public BorrowController(LibraryDbContext context) => _context = context;


        [HttpPost("BorrowBook/{bookId:int}")]
        public async Task<IActionResult> BorrowBook([FromRoute] int bookId)
        {
            int userId = int.Parse(User.FindFirst(ClaimTypes.NameIdentifier)!.Value);

            var book = await _context.Books.FindAsync(bookId);
            if (book is null || !book.IsAvailable)
                return NotFound("Book not available for borrowing.");

            book.IsAvailable = false;
            _context.BorrowRecords.Add(new BorrowRecord
            {
                UserId = userId,
                BookId = bookId,
                BorrowedAt = DateTime.UtcNow
            });

            await _context.SaveChangesAsync();
            return Ok("Book borrowed successfully.");
        }

        [HttpPost("returnBook/{bookId:int}")]
        public async Task<IActionResult> ReturnBook([FromRoute] int bookId)
        {
            int userId = int.Parse(User.FindFirst(ClaimTypes.NameIdentifier)!.Value);

            var borrowRecord = await _context.BorrowRecords
                .FirstOrDefaultAsync(br => br.UserId == userId && br.BookId == bookId && br.ReturnedAt == null);
            if (borrowRecord is null) return NotFound("Borrow record not found.");

            borrowRecord.ReturnedAt = DateTime.UtcNow;

            var book = await _context.Books.FindAsync(bookId);
            if (book != null) book.IsAvailable = true;

            await _context.SaveChangesAsync();
            return Ok("Book returned successfully.");
        }

        [HttpGet("my/all")]
        public async Task<IActionResult> GetMyAll()
        {
            var idClaim = User.FindFirstValue(ClaimTypes.NameIdentifier);
            if (!int.TryParse(idClaim, out var userId)) return Unauthorized();

            var items = await _context.BorrowRecords
                .Where(r => r.UserId == userId)
                .Include(r => r.Book)
                .OrderByDescending(r => r.BorrowedAt)
                .Select(r => new BorrowRecordDTO
                {
                    Id = r.Id,
                    BookId = r.Book.Id,
                    Title = r.Book.Title,
                    Author = r.Book.Author,
                    BorrowedAt = r.BorrowedAt,
                    ReturnedAt = r.ReturnedAt
                })
                .ToListAsync();

            return Ok(items);
        }

        [HttpGet("my/ongoing")]
        public async Task<IActionResult> GetMyOngoing()
        {
            var idClaim = User.FindFirstValue(ClaimTypes.NameIdentifier);
            if (!int.TryParse(idClaim, out var userId)) return Unauthorized();

            var items = await _context.BorrowRecords
                .Where(r => r.UserId == userId && r.ReturnedAt == null)
                .Include(r => r.Book)
                .OrderByDescending(r => r.BorrowedAt)
                .Select(r => new BorrowRecordDTO
                {
                    Id = r.Id,                 
                    BookId = r.Book.Id,
                    Title = r.Book.Title,
                    Author = r.Book.Author,
                    BorrowedAt = r.BorrowedAt,
                    ReturnedAt = r.ReturnedAt
                })
                .ToListAsync();

            return Ok(items);
        }

        [HttpGet("GetAllOngoingRecords")]
        public async Task<IActionResult> GetAllOngoingRecords(CancellationToken ct)
        {
            var records = await _context.BorrowRecords
                .AsNoTracking()
                .Where(r => r.ReturnedAt == null)
                .OrderByDescending(r => r.BorrowedAt)
                .Select(r => new BorrowRecordDTO
                {
                    Id = r.Id,                
                    BookId = r.Book.Id,        
                    Title = r.Book.Title,
                    Author = r.Book.Author,
                    BorrowedAt = r.BorrowedAt,
                    ReturnedAt = r.ReturnedAt
                })
                .ToListAsync(ct);

            return Ok(records);
        }

        [HttpGet("GetAllTimeRecords")]
        public async Task<IActionResult> GetAllTimeRecords(CancellationToken ct)
        {
            var records = await _context.BorrowRecords
                .AsNoTracking()
                .OrderByDescending(r => r.BorrowedAt)
                .Select(r => new BorrowRecordDTO
                {
                    Id = r.Id,                 
                    BookId = r.Book.Id,      
                    Title = r.Book.Title,
                    Author = r.Book.Author,
                    BorrowedAt = r.BorrowedAt,
                    ReturnedAt = r.ReturnedAt
                })
                .ToListAsync(ct);

            return Ok(records);
        }
    }
}

