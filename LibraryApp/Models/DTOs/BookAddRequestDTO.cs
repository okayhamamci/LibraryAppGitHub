namespace LibraryApp.Models.DTOs
{
    public class BookAddRequestDTO
    {
        public String Title { get; set; }
        public String Author { get; set; }
        public String Genre { get; set; }
        public int Page { get; set; }
        public String Description { get; set; }
        public double Rating { get; set; }

    }
}
