namespace LibraryApp.Models
{
    public class BorrowRecord
    {
        public int Id { get; set; }
        public int BookId { get; set; }
        public Book Book { get; set; }

        public int UserId { get; set; }
        public User User { get; set; }

        public DateTime BorrowedAt { get; set; }
        public DateTime? ReturnedAt { get; set; }
    }

}
